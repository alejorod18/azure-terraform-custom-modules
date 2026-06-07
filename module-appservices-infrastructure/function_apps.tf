resource "azurerm_storage_account" "function" {
  count                    = local.function_apps_properties != {} ? 1 : 0
  name                     = "fn${replace(var.identifier, "-", "")}"
  tags                     = data.azurerm_resource_group.rg.tags
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "function" {
  for_each            = local.function_apps_properties
  name                = "appinsights-${each.key}-${local.environment}"
  tags                = data.azurerm_resource_group.rg.tags
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = each.value.application_type
}

resource "azurerm_linux_function_app" "function" {
  for_each                    = local.function_apps_properties
  name                        = "fn-${each.key}-${local.environment}"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  tags                        = data.azurerm_resource_group.rg.tags
  service_plan_id             = azurerm_service_plan.app_service.id
  storage_account_name        = azurerm_storage_account.function[0].name
  storage_account_access_key  = azurerm_storage_account.function[0].primary_access_key
  functions_extension_version = "~4"
  enabled                     = true
  https_only                  = true

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.mi.id]
  }

  key_vault_reference_identity_id = data.azurerm_user_assigned_identity.mi.id
  virtual_network_subnet_id       = var.subnet_id

  site_config {
    vnet_route_all_enabled            = true
    always_on                         = local.app_function_allways_on
    http2_enabled                     = true
    remote_debugging_enabled          = false
    ftps_state                        = "FtpsOnly"
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Deny"

    application_insights_connection_string = azurerm_application_insights.function[each.key].connection_string
    application_insights_key               = azurerm_application_insights.function[each.key].instrumentation_key

    dynamic "application_stack" {
      for_each = each.value.application_stack
      content {
        java_version   = lookup(each.value.application_stack, "java_version", null)
        node_version   = lookup(each.value.application_stack, "node_version", null)
        python_version = lookup(each.value.application_stack, "python_version", null)
      }
    }

    dynamic "ip_restriction" {
      for_each = concat(var.subnets_id_whitelist, [var.subnet_id], each.value.subnets_id_whitelist)
      content {
        virtual_network_subnet_id = ip_restriction.value
      }
    }

    dynamic "ip_restriction" {
      for_each = concat(var.ip_range_whitelist, local.users_ip_range_whitelist, each.value.ip_range_whitelist)
      content {
        ip_address = ip_restriction.value
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = concat(var.scm_subnets_id_whitelist, each.value.scm_subnets_id_whitelist)
      content {
        virtual_network_subnet_id = scm_ip_restriction.value
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = concat(var.scm_ip_range_whitelist, local.users_ip_range_whitelist, each.value.scm_ip_range_whitelist)
      content {
        ip_address = scm_ip_restriction.value
      }
    }
  }

  app_settings = each.value.app_settings
}
