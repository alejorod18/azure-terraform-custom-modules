resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count                          = var.log_analytics_workspace_id != "" ? 1 : 0
  name                           = "ds-cosmos-${var.identifier}"
  target_resource_id             = local.cosmos_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "MongoRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_log {
    category = "PartitionKeyRUConsumption"
  }

  enabled_log {
    category = "ControlPlaneRequests"
  }

  enabled_log {
    category = "CassandraRequests"
  }

  enabled_log {
    category = "GremlinRequests"
  }

  enabled_log {
    category = "TableApiRequests"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
