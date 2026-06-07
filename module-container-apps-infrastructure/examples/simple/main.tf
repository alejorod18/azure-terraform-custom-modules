provider "azurerm" {
  features {}
  subscription_id = "<your-azure-subscription-id>"
}

data "azurerm_resource_group" "example" {
  name = "test-git"
}

module "simple_container_app" {
  source = "../../"

  identifier                 = "example-container"
  resource_group_name        = data.azurerm_resource_group.example.name
  log_analytics_workspace_id = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-common-adm-dev/providers/Microsoft.OperationalInsights/workspaces/log-common-adm-dev"

  container_apps = {
    # Container App 1
    "app1" = {
      cpu                   = 0.5
      memory                = "1Gi"
      port                  = 80
      min_replicas          = 1
      max_replicas          = 3
      environment_variables = { "EXAMPLE_ENV_VAR" = "example-secret-name" }
    }

    # Container App 2
    "app2" = {
      cpu                   = 1
      memory                = "2Gi"
      port                  = 80
      min_replicas          = 2
      max_replicas          = 5
      environment_variables = { "APP_ENV" = "staging" }
    }

    # Container App 3
    "app3" = {
      cpu          = 0.25
      memory       = "0.5Gi"
      port         = 80
      min_replicas = 1
      max_replicas = 2
      environment_variables = {
        "DEBUG_MODE" = "true"
        "LOG_LEVEL"  = "info"
      }
    }
  }

  container_registry_login_server = data.azurerm_container_registry.acr.login_server
  managed_identity_name           = azurerm_user_assigned_identity.example.name
  subnet_id                       = azurerm_subnet.subnet.id
}