variable "name" {
  type        = string
  description = "Name prefix for security groups (e.g. myapp-dev)"
}

variable "vpc_id" {
  type        = string
  description = "VPC where security groups are created"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}

variable "ecs_task_container_ports" {
  type        = list(number)
  description = "Distinct container ports to allow from the ALB into ECS task ENIs"
}
