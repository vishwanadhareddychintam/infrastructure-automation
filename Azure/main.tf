resource "azurerm_resource_group" "network" {
  name     = "${var.name_prefix}-${var.environment}-rg"
  location = var.location

  tags = {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "networking" {
  source = "./modules/networking"

  resource_group_name          = azurerm_resource_group.network.name
  location                     = var.location
  name_prefix                  = "${var.name_prefix}-${var.environment}"
  vnet_address_space           = var.vnet_address_space
  public_subnet_prefixes       = var.public_subnet_prefixes
  private_subnet_prefixes      = var.private_subnet_prefixes
  container_apps_subnet_prefix = var.container_apps_subnet_prefix
  app_gateway_subnet_prefix    = var.app_gateway_subnet_prefix
  tags = {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
