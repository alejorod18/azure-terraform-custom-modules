resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count                          = var.log_analytics_workspace_id != "" ? 1 : 0
  name                           = "ds-cosmos-${var.identifier}"
  target_resource_id             = azurerm_mssql_server.primary.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "AzureDiagnostics"


  enabled_log {
    category = "PostgreSQLLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
  lifecycle {
    ignore_changes = [
      log_analytics_destination_type
    ]
  }
}
