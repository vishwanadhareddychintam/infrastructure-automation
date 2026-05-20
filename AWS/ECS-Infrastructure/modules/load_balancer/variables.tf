variable "name" {
  type        = string
  description = "Name prefix for target group/rule tags and fallback TG names"
}

variable "alb_name" {
  type        = string
  description = "Application Load Balancer name attribute (max 32 characters in AWS)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "At least two public subnet IDs for the internet-facing ALB"

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Provide at least two public subnet IDs."
  }
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID attached to the ALB"
}

variable "target_groups" {
  type = map(object({
    port                 = number
    protocol             = optional(string, "HTTP")
    health_check_path    = optional(string, "/")
    health_check_matcher = optional(string, "200-399")
    target_group_name    = optional(string)
  }))
  description = "Resolved target groups; target_group_name when set becomes the AWS TG name (max 32 chars applied in resource)."

  validation {
    condition     = length(var.target_groups) > 0
    error_message = "Define at least one target group."
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
  description = "HTTPS (443) listener rules only; HTTP has no rules (lower priority number evaluated first)"
  default     = []

  validation {
    condition     = length(distinct([for r in var.alb_listener_rules : r.priority])) == length(var.alb_listener_rules)
    error_message = "Each rule must have a unique priority."
  }

  validation {
    condition = alltrue([
      for r in var.alb_listener_rules :
      length(coalesce(r.host_headers, [])) > 0 || length(coalesce(r.path_patterns, [])) > 0
    ])
    error_message = "Each rule needs at least one host_header or path_pattern value."
  }
}

variable "alb_idle_timeout" {
  type        = number
  description = "ALB idle timeout in seconds"
  default     = 60
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in the same region as the ALB (e.g. wildcard *.example.com)"
}

variable "ssl_policy" {
  type        = string
  description = "ALB SSL/TLS security policy for the HTTPS listener"
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
}

variable "https_default_fixed_response" {
  type = object({
    content_type = string
    message_body = string
    status_code  = string
  })
  description = "Default action for HTTPS when no rule matches (intended 503 maintenance-style response)"
  default = {
    content_type = "text/plain"
    message_body = "Service Unavailable"
    status_code  = "503"
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
