locals {
  listener_keys = sort(keys(var.listener_rules))
  app_keys      = distinct([for r in var.listener_rules : r.app_key])
}

resource "azurerm_application_gateway" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.enable_waf ? "WAF_v2" : "Standard_v2"
    tier     = var.enable_waf ? "WAF_v2" : "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = var.public_ip_id
  }

  ssl_certificate {
    name                = "appgw-cert"
    key_vault_secret_id = var.certificate_secret_id
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_fqdns
    content {
      name  = "pool-${backend_address_pool.key}"
      fqdns = [backend_address_pool.value]
    }
  }

  dynamic "backend_http_settings" {
    for_each = toset(local.app_keys)
    content {
      name                                = "settings-${backend_http_settings.value}"
      cookie_based_affinity               = "Disabled"
      port                                = 80
      protocol                            = "Http"
      request_timeout                     = 60
      pick_host_name_from_backend_address = true
      probe_name                          = "probe-${backend_http_settings.value}"
    }
  }

  dynamic "probe" {
    for_each = toset(local.app_keys)
    content {
      name                                      = "probe-${probe.value}"
      protocol                                  = "Http"
      path                                      = try([for k, r in var.listener_rules : r.probe_path if r.app_key == probe.value][0], "/")
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true
      minimum_servers                           = 0
    }
  }

  dynamic "http_listener" {
    for_each = var.listener_rules
    content {
      name                           = "https-${http_listener.key}"
      frontend_ip_configuration_name = "frontend-ip"
      frontend_port_name             = "https-port"
      protocol                       = "Https"
      ssl_certificate_name           = "appgw-cert"
      host_names                     = [http_listener.value.host_header]
    }
  }

  http_listener {
    name                           = "http-redirect"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  dynamic "request_routing_rule" {
    for_each = { for idx, k in local.listener_keys : k => idx }
    content {
      name                       = "route-${request_routing_rule.key}"
      rule_type                  = "Basic"
      http_listener_name         = "https-${request_routing_rule.key}"
      priority                   = 100 + request_routing_rule.value * 10
      backend_address_pool_name  = "pool-${var.listener_rules[request_routing_rule.key].app_key}"
      backend_http_settings_name = "settings-${var.listener_rules[request_routing_rule.key].app_key}"
    }
  }

  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https-${var.default_listener_key}"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "http-redirect-rule"
    rule_type                   = "Basic"
    http_listener_name          = "http-redirect"
    priority                    = 1
    redirect_configuration_name = "http-to-https"
  }

  dynamic "waf_configuration" {
    for_each = var.enable_waf ? [1] : []
    content {
      enabled          = true
      firewall_mode    = "Prevention"
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"
    }
  }

  tags = var.tags
}
