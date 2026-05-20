variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (optional if using Azure CLI default)"
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region (must match networking stack)"
}

variable "name_prefix" {
  type        = string
  description = "Application name prefix for tags and resource names"
}

variable "environment" {
  type        = string
  description = "Environment suffix (dev, staging, prod)"
}

variable "container_apps_subnet_id" {
  type        = string
  description = "Delegated subnet ID from Phase 1 (container_apps_subnet_id)"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID from Phase 1"
}

variable "app_gateway_subnet_id" {
  type        = string
  description = "Dedicated Application Gateway subnet ID from Phase 1"
}

variable "app_gateway_public_ip_id" {
  type        = string
  description = "Public IP resource ID for Application Gateway from Phase 1"
}

variable "app_gateway_public_ip_address" {
  type        = string
  description = "Application Gateway public IP address from Phase 1 (for DNS A records)"
}

variable "container_app_definitions" {
  type = map(object({
    container_name   = string
    image            = string
    cpu              = number
    memory           = string
    container_port   = number
    health_check_path = optional(string, "/")
    min_replicas     = optional(number, 1)
    max_replicas     = optional(number, 3)
    env_vars         = optional(map(string), {})
  }))
  description = "Exactly four Container Apps (svc01–svc04)"

  validation {
    condition     = length(var.container_app_definitions) == 4
    error_message = "Provide exactly four entries in container_app_definitions."
  }
}

variable "service_short_names" {
  type = map(string)
  default = {
    svc01 = "api1"
    svc02 = "api2"
    svc03 = "api3"
    svc04 = "web"
  }

  validation {
    condition     = sort(keys(var.service_short_names)) == tolist(["svc01", "svc02", "svc03", "svc04"])
    error_message = "service_short_names must contain keys svc01 through svc04."
  }
}

variable "dns_zone_name" {
  type        = string
  description = "Public DNS zone name (e.g. example.com)"
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "Resource group containing the public DNS zone"
}

variable "dns_route_container_apps" {
  type        = map(string)
  description = "Maps DNS keys to container app keys (svc01–svc04)"

  validation {
    condition = alltrue([
      for v in values(var.dns_route_container_apps) :
      contains(["svc01", "svc02", "svc03", "svc04"], v)
    ])
    error_message = "dns_route_container_apps values must be svc01 through svc04."
  }
}

variable "dns_hostnames" {
  type        = map(string)
  description = "Optional FQDN override per dns_route_container_apps key"
  default     = {}
}

variable "default_dns_listener_key" {
  type        = string
  description = "DNS key from dns_route_container_apps for HTTP→HTTPS redirect target (e.g. web or root)"
  default     = "web"
}

variable "acr_login_server" {
  type        = string
  description = "Azure Container Registry login server (e.g. myacr.azurecr.io); leave empty for public images only"
  default     = ""
}

variable "acr_resource_id" {
  type        = string
  description = "ACR resource ID for AcrPull role assignment; required when using ACR images"
  default     = null
}

variable "key_vault_certificate_secret_id" {
  type        = string
  description = "Key Vault secret ID for Application Gateway HTTPS certificate (required for HTTPS listener)"
}

variable "enable_waf" {
  type        = bool
  description = "Enable Web Application Firewall on Application Gateway"
  default     = true
}
