resource "azurerm_container_app" "container_app" {
  for_each                     = local.container_apps_properties
  name                         = "ca-${each.key}-${local.environment}"
  container_app_environment_id = azurerm_container_app_environment.container_env.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  tags                         = data.azurerm_resource_group.rg.tags
  revision_mode                = "Single"

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
      workload_profile_name
    ]
  }

  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name                = lower(replace(secret.key, "_", "-"))
      key_vault_secret_id = secret.value
      identity            = data.azurerm_user_assigned_identity.mi.id
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.mi.id]
  }

  registry {
    identity = data.azurerm_user_assigned_identity.mi.id
    server   = var.container_registry_login_server
  }

  template {
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas

    container {
      name   = each.key
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = each.value.cpu
      memory = each.value.memory

      dynamic "env" {
        for_each = each.value.secrets

        content {
          name        = env.key
          secret_name = lower(replace(env.key, "_", "-"))
        }
      }

      dynamic "env" {
        for_each = each.value.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }


  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = each.value.port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
