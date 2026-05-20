output "resource_group_name" {
  description = "Networking resource group name"
  value       = azurerm_resource_group.network.name
}

output "resource_group_id" {
  description = "Networking resource group ID"
  value       = azurerm_resource_group.network.id
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "virtual_network_id" {
  description = "Virtual network ID"
  value       = module.networking.virtual_network_id
}

output "virtual_network_name" {
  description = "Virtual network name"
  value       = module.networking.virtual_network_name
}

output "public_subnet_ids" {
  description = "Public subnet IDs (Application Gateway)"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "container_apps_subnet_id" {
  description = "Delegated subnet ID for Container Apps Environment (Phase 2)"
  value       = module.networking.container_apps_subnet_id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.networking.nat_gateway_id
}

output "app_gateway_subnet_id" {
  description = "Dedicated Application Gateway subnet ID (Phase 2)"
  value       = module.networking.app_gateway_subnet_id
}

output "app_gateway_public_ip_id" {
  description = "Application Gateway public IP ID (Phase 2)"
  value       = module.networking.app_gateway_public_ip_id
}

output "app_gateway_public_ip_address" {
  description = "Application Gateway public IP address for DNS (Phase 2)"
  value       = module.networking.app_gateway_public_ip_address
}

output "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace ID if created in networking module"
  value       = module.networking.log_analytics_workspace_id
}
