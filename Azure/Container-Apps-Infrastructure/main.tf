resource "azurerm_resource_group" "apps" {
  name     = "${var.name_prefix}-${var.environment}-apps-rg"
  location = var.location

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "apps" {
  name                = "${local.name}-aca-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.apps.name

  tags = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_resource_id != null ? 1 : 0

  scope                = var.acr_resource_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.apps.principal_id
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${local.name}-aca-env"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.apps.name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.container_apps_subnet_id

  tags = local.tags
}

module "container_app" {
  source   = "./modules/container_app"
  for_each = var.container_app_definitions

  name                         = "${local.name}-${var.service_short_names[each.key]}"
  resource_group_name          = azurerm_resource_group.apps.name
  location                     = var.location
  container_app_environment_id = azurerm_container_app_environment.main.id
  managed_identity_id          = azurerm_user_assigned_identity.apps.id
  acr_login_server             = var.acr_login_server
  definition                   = each.value
  tags                         = local.tags
}

module "application_gateway" {
  source = "./modules/application_gateway"

  name                  = "${local.name}-appgw"
  resource_group_name   = azurerm_resource_group.apps.name
  location              = var.location
  app_gateway_subnet_id = var.app_gateway_subnet_id
  public_ip_id          = var.app_gateway_public_ip_id
  backend_fqdns = {
    for k, m in module.container_app : k => m.ingress_fqdn
  }
  listener_rules = {
    for dns_key, app_key in var.dns_route_container_apps :
    dns_key => {
      host_header = local.dns_fqdns[dns_key]
      app_key     = app_key
      probe_path  = var.container_app_definitions[app_key].health_check_path
    }
  }
  default_listener_key  = var.default_dns_listener_key
  certificate_secret_id = var.key_vault_certificate_secret_id
  enable_waf            = var.enable_waf
  tags                  = local.tags

  depends_on = [module.container_app]
}

resource "azurerm_dns_a_record" "apps" {
  for_each = var.dns_route_container_apps

  name                = "${var.name_prefix}-${each.key}-${var.environment}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [var.app_gateway_public_ip_address]
}
