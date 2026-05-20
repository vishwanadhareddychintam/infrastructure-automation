variable "service_key" {
  type        = string
  description = "Stable key for this service (matches ecs_task_definitions map key)"
}

variable "service_name" {
  type        = string
  description = "AWS ECS service name (e.g. myapp-dev-api1)"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name (CloudWatch log group path segment)"
}

variable "cluster_id" {
  type        = string
  description = "ECS cluster ID (id attribute)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets for Fargate ENIs"
}

variable "ecs_tasks_security_group_id" {
  type        = string
  description = "Security group for task ENIs"
}

variable "execution_role_arn" {
  type        = string
  description = "Default ECS task execution role from the cluster module"
}

variable "cluster_task_role_arn" {
  type        = string
  description = "Default ECS task IAM role for runtime AWS API calls (when task.task_role_arn is unset)"
}

variable "task" {
  type = object({
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
  })
  description = "Task definition settings; health_check_path is forwarded for ALB target group configuration only. secrets inject env vars from Secrets Manager or SSM (valueFrom = ARN). task_role_arn overrides cluster_task_role_arn."
}

variable "service" {
  type = object({
    desired_count                      = optional(number, 1)
    assign_public_ip                   = optional(bool, false)
    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_maximum_percent         = optional(number, 200)
    enable_execute_command             = optional(bool, false)
    propagate_tags                     = optional(string, "NONE")
  })
  description = "ECS service settings"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags"
}

variable "target_group_arn" {
  type        = string
  nullable    = true
  default     = null
  description = "ALB target group ARN; ECS registers task IPs with this group (must match this service's listener rule TG)"
}
