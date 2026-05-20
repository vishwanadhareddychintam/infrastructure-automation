variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "managed_identity_id" {
  type = string
}

variable "acr_login_server" {
  type    = string
  default = ""
}

variable "definition" {
  type = object({
    container_name    = string
    image             = string
    cpu               = number
    memory            = string
    container_port    = number
    health_check_path = optional(string, "/")
    min_replicas      = optional(number, 1)
    max_replicas      = optional(number, 3)
    env_vars          = optional(map(string), {})
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
