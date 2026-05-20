output "resource_group_name" {
  value = azurerm_resource_group.apps.name
}

output "container_app_environment_id" {
  value = azurerm_container_app_environment.main.id
}

output "container_app_fqdns" {
  description = "Internal ingress FQDNs keyed by svc01–svc04"
  value       = { for k, m in module.container_app : k => m.ingress_fqdn }
}

output "application_gateway_id" {
  value = module.application_gateway.id
}

output "dns_fqdns" {
  description = "Public DNS names (logical key -> FQDN)"
  value       = local.dns_fqdns
}

output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.apps.principal_id
}
