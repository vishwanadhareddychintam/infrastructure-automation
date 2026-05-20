output "id" {
  value = azurerm_container_app.main.id
}

output "name" {
  value = azurerm_container_app.main.name
}

output "ingress_fqdn" {
  description = "Default FQDN for internal ingress (Application Gateway backend)"
  value       = azurerm_container_app.main.ingress[0].fqdn
}

output "latest_revision_fqdn" {
  value = azurerm_container_app.main.latest_revision_fqdn
}
