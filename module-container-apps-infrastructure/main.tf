resource "azurerm_application_insights" "container_app" {
  name                = "ai-${var.identifier}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  retention_in_days   = 30
  tags                = data.azurerm_resource_group.rg.tags
  lifecycle {
    ignore_changes = [
      location
    ]
  }
}

resource "azurerm_container_app_environment" "container_env" {
  name                                        = "cae-${var.identifier}"
  location                                    = data.azurerm_resource_group.rg.location
  resource_group_name                         = var.resource_group_name
  log_analytics_workspace_id                  = var.log_analytics_workspace_id
  dapr_application_insights_connection_string = azurerm_application_insights.container_app.connection_string
  infrastructure_subnet_id                    = var.subnet_id
  internal_load_balancer_enabled              = var.internal_load_balancer_enabled # no public IP
  zone_redundancy_enabled                     = local.zone_redundancy_enabled
  tags                                        = data.azurerm_resource_group.rg.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
  lifecycle {
    ignore_changes = [
      infrastructure_resource_group_name
    ]
  }
}

