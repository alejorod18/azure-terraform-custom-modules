resource "azurerm_monitor_diagnostic_setting" "key_vault_all_metrics" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "ds-kv-${var.identifier}"
  target_resource_id         = azurerm_key_vault.secrets.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log {
    category = "AuditEvent"
  }
  metric {
    category = "AllMetrics"
  }
  depends_on = [azurerm_key_vault.secrets]
}

