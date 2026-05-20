locals {
  name = "${var.name_prefix}-${var.environment}"

  tags = {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  dns_fqdns = {
    for dns_key, _ in var.dns_route_container_apps :
    dns_key => coalesce(
      try(var.dns_hostnames[dns_key], null),
      "${var.name_prefix}-${dns_key}-${var.environment}.${var.dns_zone_name}"
    )
  }

}
