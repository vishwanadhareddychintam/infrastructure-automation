variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_gateway_subnet_id" {
  type        = string
  description = "Dedicated subnet for Application Gateway (no other resources)"
}

variable "public_ip_id" {
  type = string
}

variable "backend_fqdns" {
  type        = map(string)
  description = "Container App ingress FQDN per app key (svc01–svc04)"
}

variable "listener_rules" {
  type = map(object({
    host_header = string
    app_key     = string
    probe_path  = string
  }))
  description = "One entry per public hostname (supports multiple DNS names per app)"
}

variable "default_listener_key" {
  type        = string
  description = "DNS listener key used as HTTP redirect target"
}

variable "certificate_secret_id" {
  type = string
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
