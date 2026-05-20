output "virtual_network_id" {
  value = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

output "public_subnet_ids" {
  value = azurerm_subnet.public[*].id
}

output "private_subnet_ids" {
  value = azurerm_subnet.private[*].id
}

output "container_apps_subnet_id" {
  value = azurerm_subnet.container_apps.id
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.main.id
}

output "app_gateway_subnet_id" {
  description = "Dedicated subnet ID for Application Gateway (Phase 2)"
  value       = azurerm_subnet.app_gateway.id
}

output "app_gateway_public_ip_id" {
  description = "Static public IP ID for Application Gateway (Phase 2)"
  value       = azurerm_public_ip.appgw.id
}

output "app_gateway_public_ip_address" {
  description = "Application Gateway public IP address for DNS A records"
  value       = azurerm_public_ip.appgw.ip_address
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.platform.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.platform.name
}
