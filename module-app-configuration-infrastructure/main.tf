resource "azurerm_app_configuration" "appconf" {
  name                       = "appconf-${var.identifier}"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  sku                        = var.sku
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days
  local_auth_enabled         = var.local_auth_enabled
  public_network_access      = "Enabled"

  dynamic "identity" {
    for_each = data.azurerm_user_assigned_identity.keyvault_mi.id != "" ? toset(["enabled"]) : toset([])
    content {
      type         = "UserAssigned"
      identity_ids = [data.azurerm_user_assigned_identity.keyvault_mi.id]
    }
  }

  dynamic "replica" {
    for_each = local.replica_enabled ? toset(["enabled"]) : toset([])
    content {
      name     = "drp"
      location = "West US"
    }
  }

  tags = data.azurerm_resource_group.rg.tags
}

resource "azurerm_role_assignment" "appconf_data_owner" {
  scope                = azurerm_app_configuration.appconf.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "appconf_data_reader" {
  count                = var.reader_managed_identity_name != "" ? 1 : 0
  scope                = azurerm_app_configuration.appconf.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = data.azurerm_user_assigned_identity.reader_mi.principal_id
}

resource "azurerm_app_configuration_key" "variables" {
  for_each               = var.variables
  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = each.key
  value                  = each.value
  tags                   = data.azurerm_resource_group.rg.tags
  depends_on = [
    azurerm_role_assignment.appconf_data_owner
  ]
}

resource "azurerm_app_configuration_key" "secrets" {
  count = length(keys(local.processed_secrets))

  configuration_store_id = azurerm_app_configuration.appconf.id
  key                    = element(keys(local.processed_secrets), count.index)
  type                   = "vault"
  vault_key_reference    = element(values(local.processed_secrets), count.index)
  tags                   = data.azurerm_resource_group.rg.tags
}

resource "null_resource" "set_public_network_access_false" {
  count = var.enable_public_access ? 0 : 1
  triggers = {
    public_network_access = var.enable_public_access
  }
  provisioner "local-exec" {
    command = <<EOT
     az appconfig update --name ${azurerm_app_configuration.appconf.name} \
                    --subscription ${data.azurerm_client_config.current.subscription_id} \
                    --resource-group ${azurerm_app_configuration.appconf.resource_group_name} \
                    --enable-public-network ${var.enable_public_access}

    EOT
  }
  depends_on = [
    azurerm_app_configuration_key.secrets,
    azurerm_app_configuration_key.variables
  ]
}
