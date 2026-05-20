variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (optional if set via ARM_SUBSCRIPTION_ID or Azure CLI default)"
  default     = null
}

variable "location" {
  type        = string
  description = "Azure region (e.g. eastus, westeurope)"
  default     = "eastus"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for the virtual network"
  default     = "10.0.0.0/16"
}

variable "public_subnet_prefixes" {
  type        = list(string)
  description = "Two public subnet prefixes (Application Gateway / ingress)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_prefixes" {
  type        = list(string)
  description = "Two private subnet prefixes (general workloads)"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "container_apps_subnet_prefix" {
  type        = string
  description = "Subnet for Azure Container Apps environment (minimum /23, delegated to Microsoft.App/environments)"
  default     = "10.0.8.0/23"
}

variable "app_gateway_subnet_prefix" {
  type        = string
  description = "Dedicated subnet for Application Gateway only (Azure requirement)"
  default     = "10.0.16.0/24"
}

variable "name_prefix" {
  type        = string
  description = "Base name prefix for resources and tags"
}

variable "environment" {
  type        = string
  description = "Environment suffix (dev, staging, prod)"
}
