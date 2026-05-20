variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "public_subnet_prefixes" {
  type = list(string)
}

variable "private_subnet_prefixes" {
  type = list(string)
}

variable "container_apps_subnet_prefix" {
  type = string
}

variable "app_gateway_subnet_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
