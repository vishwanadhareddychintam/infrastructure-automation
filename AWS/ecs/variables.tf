variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name"
}

variable "aws_region" {
  type        = string
  description = "AWS region (must match VPC region)"
  default     = "us-east-1"
}

variable "name_prefix" {
  type        = string
  description = "Base name prefix for tags and generated resource names"
}

variable "environment" {
  type        = string
  description = "Environment suffix (e.g. dev, staging, prod)"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name override; default is <name_prefix>-<environment>-ecs"
  default     = null
}

variable "alb_name" {
  type        = string
  description = "ALB name override (max 32 chars); default is <name_prefix>-<environment>-alb"
  default     = null
}

variable "ecs_service_name_prefix" {
  type        = string
  description = "Prefix for aws_ecs_service name: <prefix>-<environment>-<service_short_name>"
  default     = null
}

variable "service_short_names" {
  type        = map(string)
  description = "Short label per svc01–svc07 for ECS service and target group names"

  default = {
    svc01 = "api1"
    svc02 = "api2"
    svc03 = "api3"
    svc04 = "api4"
    svc05 = "api5"
    svc06 = "api6"
    svc07 = "web"
  }

  validation {
    condition     = sort(keys(var.service_short_names)) == tolist(["svc01", "svc02", "svc03", "svc04", "svc05", "svc06", "svc07"])
    error_message = "service_short_names must contain exactly keys svc01 through svc07."
  }
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID (e.g. from networking stack terraform output vpc_id)"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "At least two public subnet IDs in different AZs for the internet-facing ALB"

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Provide at least two public subnet IDs for the load balancer."
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "At least two private subnet IDs for ECS Fargate services (awsvpc)"

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Provide at least two private subnet IDs."
  }
}

variable "ecs_task_definitions" {
  type = map(object({
    cpu                = number
    memory             = number
    container_name     = string
    image              = string
    container_port     = optional(number, 80)
    health_check_path  = optional(string, "/")
    execution_role_arn = optional(string, null)
    task_role_arn      = optional(string, null)
    log_retention_days = optional(number, 7)
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
  }))
  description = "Exactly seven Fargate task definitions; keys must match ecs_services. health_check_path is used by the ALB target group. secrets = env var name + Secrets Manager or SSM ARN."

  validation {
    condition     = length(var.ecs_task_definitions) == 7
    error_message = "Provide exactly seven entries in ecs_task_definitions."
  }
}

variable "ecs_services" {
  type = map(object({
    desired_count                      = optional(number, 1)
    assign_public_ip                   = optional(bool, false)
    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_maximum_percent         = optional(number, 200)
    enable_execute_command             = optional(bool, false)
    propagate_tags                     = optional(string, "NONE")
  }))
  description = "Exactly seven ECS services; keys must match ecs_task_definitions."

  validation {
    condition     = length(var.ecs_services) == 7
    error_message = "Provide exactly seven entries in ecs_services."
  }
}

variable "target_groups" {
  type = map(object({
    port                    = optional(number)
    ecs_task_definition_key = optional(string)
    protocol                = optional(string, "HTTP")
    health_check_path       = optional(string, "/")
    health_check_matcher    = optional(string, "200-399")
  }))
  description = "Exactly seven ALB target groups (svc01–svc07). Use ecs_task_definition_key to inherit port and health path from the task."

  validation {
    condition     = sort(keys(var.target_groups)) == tolist(["svc01", "svc02", "svc03", "svc04", "svc05", "svc06", "svc07"])
    error_message = "target_groups must contain exactly keys svc01 through svc07."
  }
}

variable "default_target_group_key" {
  type        = string
  description = "Key in target_groups for output aliases; ALB HTTP redirects to HTTPS"
}

variable "route53_domain_name" {
  type        = string
  description = "Public DNS zone apex (e.g. example.com). Used when route53_hosted_zone_id is unset."
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "Existing Route 53 hosted zone ID; if null, zone is resolved by route53_domain_name"
  default     = null
}

variable "dns_hostnames" {
  type        = map(string)
  description = "Optional FQDN override per dns_route_target_groups key; default is <name_prefix>-<key>-<environment>.<route53_domain_name>"
  default     = {}
}

variable "dns_route_target_groups" {
  type        = map(string)
  description = "Maps DNS record keys to target_groups keys (svc01–svc07) for HTTPS host-header rules"

  validation {
    condition = alltrue([
      for v in values(var.dns_route_target_groups) :
      contains(["svc01", "svc02", "svc03", "svc04", "svc05", "svc06", "svc07"], v)
    ])
    error_message = "dns_route_target_groups values must be svc01 through svc07."
  }
}

variable "alb_listener_rules" {
  type = list(object({
    name             = string
    priority         = number
    target_group_key = string
    host_headers     = optional(list(string))
    path_patterns    = optional(list(string))
  }))
  description = "Extra HTTPS listener rules after auto DNS rules (use priorities > 80)"
  default     = []

  validation {
    condition     = length(distinct([for r in var.alb_listener_rules : r.priority])) == length(var.alb_listener_rules)
    error_message = "Each alb_listener_rules entry must have a unique priority."
  }

  validation {
    condition = alltrue([
      for r in var.alb_listener_rules :
      length(coalesce(r.host_headers, [])) > 0 || length(coalesce(r.path_patterns, [])) > 0
    ])
    error_message = "Each rule needs at least one host_header or path_pattern."
  }
}

variable "alb_idle_timeout" {
  type        = number
  description = "ALB idle timeout in seconds"
  default     = 60
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in the ALB region (e.g. wildcard *.example.com)"
}

variable "alb_ssl_policy" {
  type        = string
  description = "Predefined ALB security policy for HTTPS"
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
}

variable "https_default_fixed_response" {
  type = object({
    content_type = string
    message_body = string
    status_code  = string
  })
  description = "HTTPS listener default when no rule matches"
  default = {
    content_type = "text/plain"
    message_body = "Service Unavailable"
    status_code  = "503"
  }
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable CloudWatch Container Insights on the ECS cluster"
  default     = true
}

variable "iam_user_name" {
  type        = string
  description = "IAM user name; defaults to <name_prefix>-<environment>-deployer"
  default     = null
}

variable "iam_policy_name" {
  type        = string
  description = "Customer managed policy name; defaults to <name_prefix>-<environment>-policy"
  default     = null
}

variable "iam_policy_document" {
  type        = string
  description = "JSON IAM policy document for the optional deployer IAM user (use least privilege)"
}
