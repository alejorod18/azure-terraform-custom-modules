resource "azurerm_monitor_diagnostic_setting" "ds" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "ds-kv-${var.identifier}"
  target_resource_id         = azurerm_app_configuration.appconf.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log {
    category_group = "allLogs"
  }
  metric {
    category = "AllMetrics"
  }
  depends_on = [azurerm_app_configuration.appconf]
}

