resource "azurerm_storage_account" "capture_storage" {
  count                         = var.create_capture_storage_account ? 1 : 0
  name                          = "eh${lower(replace(var.identifier, "-", ""))}"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true
  min_tls_version               = "TLS1_2"
  tags                          = data.azurerm_resource_group.rg.tags
  network_rules {
    default_action = "Deny"
    ip_rules       = local.users_ip_range_whitelist
    bypass         = ["AzureServices"]
  }
  lifecycle {
    ignore_changes = [
      network_rules[0].private_link_access
    ]
  }
}

# Contenedor dentro del Storage Account
resource "azurerm_storage_container" "capture_container" {
  count                 = var.create_capture_storage_account ? 1 : 0
  name                  = "capture-${var.identifier}"
  storage_account_id    = azurerm_storage_account.capture_storage[0].id
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.capture_storage]
}

resource "azurerm_role_assignment" "executor" {
  count                = var.create_capture_storage_account ? 1 : 0
  scope                = azurerm_storage_account.capture_storage[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "eventhub" {
  count                = var.create_capture_storage_account ? 1 : 0
  scope                = azurerm_storage_account.capture_storage[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_eventhub_namespace.ns.identity[0].principal_id
}

# Azurerm aún no tiene capacidad de modificar este elemento.Cuando ya se pueda este bloque debe ser reemplazado.
resource "null_resource" "update_eventhub_identity" {
  for_each = local.enable_storage_account_creation ? local.enabled_capture_event_hubs : {}
  provisioner "local-exec" {
    command = <<EOT
az eventhubs eventhub update \
  --resource-group ${data.azurerm_resource_group.rg.name} \
  --namespace-name ${azurerm_eventhub_namespace.ns.name} \
  --name ${each.key} \
  --set captureDescription.destination.identity.type="SystemAssigned"
EOT
  }
  depends_on = [azurerm_eventhub.eh]
}


