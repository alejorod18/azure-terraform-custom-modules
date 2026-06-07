resource "azurerm_monitor_diagnostic_setting" "app_service" {
  for_each                   = var.log_analytics_workspace_id != "" ? local.web_apps_properties : {}
  name                       = "ds-${each.key}-${var.identifier}"
  target_resource_id         = azurerm_linux_web_app.app_service[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_service_slot" {
  for_each                   = local.needs_slots && var.log_analytics_workspace_id != "" ? local.web_apps_properties : {}
  name                       = "ds-${each.key}-slot-${var.identifier}"
  target_resource_id         = azurerm_linux_web_app_slot.app_service[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  dynamic "enabled_log" {
    for_each = local.environment != "qas" ? { "deploy" : true } : {}
    content {
      category = "AppServiceAntivirusScanAuditLogs"
    }
  }

  dynamic "enabled_log" {
    for_each = local.environment != "qas" ? { "deploy" : true } : {}
    content {
      category = "AppServiceFileAuditLogs"
    }
  }

  metric {
    category = "AllMetrics"
  }
}