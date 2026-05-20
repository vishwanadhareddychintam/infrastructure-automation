variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable CloudWatch Container Insights"
  default     = true
}
