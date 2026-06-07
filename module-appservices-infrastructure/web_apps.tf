resource "azurerm_linux_web_app" "app_service" {
  for_each            = local.web_apps_properties
  name                = "as-${each.key}-${local.environment}"
  tags                = data.azurerm_resource_group.rg.tags
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.app_service.id
  enabled             = true
  https_only          = true


  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.mi.id]
  }

  key_vault_reference_identity_id = data.azurerm_user_assigned_identity.mi.id

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = "0"
        retention_in_mb   = "35"
      }
    }
  }
  dynamic "backup" {
    for_each = var.backup_storage_account_url != "" ? [1] : []
    content {
      name                = "Periodic backup"
      enabled             = true
      storage_account_url = var.backup_storage_account_url

      schedule {
        frequency_interval       = 1
        frequency_unit           = "Day"
        keep_at_least_one_backup = true
        retention_period_days    = 30
      }
    }
  }


  virtual_network_subnet_id = var.subnet_id

  site_config {
    vnet_route_all_enabled            = true
    always_on                         = data.azurerm_resource_group.rg.tags.environment != "qas" ? true : false
    http2_enabled                     = true
    remote_debugging_enabled          = false
    ftps_state                        = "FtpsOnly"
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Deny"

    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = data.azurerm_user_assigned_identity.mi.client_id

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


resource "azurerm_linux_web_app_slot" "app_service" {
  for_each       = local.needs_slots ? local.web_apps_properties : {}
  name           = "stg"
  tags           = data.azurerm_resource_group.rg.tags
  app_service_id = azurerm_linux_web_app.app_service[each.key].id
  enabled        = true
  https_only     = true


  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.mi.id]
  }

  key_vault_reference_identity_id = data.azurerm_user_assigned_identity.mi.id

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = "0"
        retention_in_mb   = "35"
      }
    }
  }

  virtual_network_subnet_id = var.subnet_id

  site_config {
    vnet_route_all_enabled            = true
    http2_enabled                     = true
    always_on                         = false
    remote_debugging_enabled          = false
    ftps_state                        = "FtpsOnly"
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Deny"


    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = data.azurerm_user_assigned_identity.mi.client_id

    dynamic "ip_restriction" {
      for_each = concat(var.subnets_id_whitelist, each.value.subnets_id_whitelist)
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

resource "azapi_update_resource" "example_vnet_container_pull_routing" {
  for_each    = local.web_apps_properties
  resource_id = azurerm_linux_web_app.app_service[each.key].id
  type        = "Microsoft.Web/sites@2022-09-01"
  body = jsonencode({
    properties = {
      vnetImagePullEnabled : true
    }
  })
  lifecycle {
    replace_triggered_by = [
      azurerm_linux_web_app.app_service[each.key]
    ]
  }
}
