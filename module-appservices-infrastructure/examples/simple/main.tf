provider "azurerm" {
  features {}
  subscription_id = "<your-azure-subscription-id>"
}

data "azurerm_resource_group" "example" {
  name = "test-git"
}

module "app_settings_example" {
  source                     = "../../"
  resource_group_name        = "test-git"
  identifier                 = "example"
  sku_name                   = "P1v2"
  zone_balancing_enabled     = false
  managed_identity_name      = azurerm_user_assigned_identity.example.name
  subnet_id                  = azurerm_subnet.subnet.id
  log_analytics_workspace_id = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-common-adm-dev/providers/Microsoft.OperationalInsights/workspaces/log-common-adm-dev"
  enable_slot                = true
  key_vault_secrets = {
    "key3"        = "value3"
    "anotherkey4" = "value4"
  }
  app_service_web_apps = {
    "app_long_long_long_long_long_long_long_long_long_long" = {
      secrets_filter_regex = "^key.*"
      "app_settings" = {
        "key1" = "value1"
        "key2" = "value2"
      }
    },
    "app2" = {
      "app_settings" = {
        "key1" = "value1"
        "key2" = "value2"
      }
    }
  }
  app_service_function_apps = {
    "fn1" = {
      "application_type" = "Node.JS"
      "application_stack" = {
        "node_version" = "14"
      }
      "app_settings" = {
        "key1" = "value1"
        "key2" = "value2"
      }
    },
    "fn2" = {
      "application_type" = "other"
      "application_stack" = {
        "python_version" = "3.8"
      }
      "app_settings" = {
        "key1" = "value1"
        "key2" = "value2"
      }
    }
  }
}

output "web_apps_hostnames" {
  value = module.app_settings_example.web_apps_hostnames
}
