resource "azurerm_container_app" "main" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  dynamic "registry" {
    for_each = var.acr_login_server != "" ? [1] : []
    content {
      server   = var.acr_login_server
      identity = var.managed_identity_id
    }
  }

  template {
    min_replicas = var.definition.min_replicas
    max_replicas = var.definition.max_replicas

    container {
      name   = var.definition.container_name
      image  = var.definition.image
      cpu    = var.definition.cpu
      memory = var.definition.memory

      dynamic "env" {
        for_each = var.definition.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.definition.container_port
        path      = var.definition.health_check_path
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.definition.container_port
        path      = var.definition.health_check_path
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = var.definition.container_port
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}
