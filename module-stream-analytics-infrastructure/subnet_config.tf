resource "azurerm_storage_account" "storage" {
  count                    = var.enable_private_access ? 1 : 0
  name                     = local.storage_identifier
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = data.azurerm_resource_group.rg.tags
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [var.subnet_id]
  }
  lifecycle {
    ignore_changes = [location, tags]
  }
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count                = var.enable_private_access ? 1 : 0
  principal_id         = azurerm_stream_analytics_job.saj.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.storage[0].id
}

resource "azurerm_role_assignment" "storage_table_data_contributor" {
  count                = var.enable_private_access ? 1 : 0
  principal_id         = azurerm_stream_analytics_job.saj.identity[0].principal_id
  role_definition_name = "Storage Table Data Contributor"
  scope                = azurerm_storage_account.storage[0].id
}

resource "null_resource" "update_stream_analytics_auth" {
  count = var.enable_private_access ? 1 : 0
  triggers = {
    saj_id = azurerm_stream_analytics_job.saj.id
  }
  provisioner "local-exec" {
    command = <<EOT
az resource update \
  --ids "${azurerm_stream_analytics_job.saj.id}" \
  --api-version "2021-10-01-preview" \
  --set properties.jobStorageAccount.accountName="${azurerm_storage_account.storage[0].name}" \
properties.jobStorageAccount.authenticationMode="Msi"

EOT
  }
  lifecycle {
    replace_triggered_by = [
      null_resource.saj.triggers
    ]
  }
  depends_on = [
    azurerm_stream_analytics_job.saj,
    azurerm_role_assignment.storage_blob_data_contributor
  ]
}


resource "null_resource" "update_stream_analytics_subnet_config" {
  count = var.enable_private_access ? 1 : 0
  triggers = {
    saj_id = azurerm_stream_analytics_job.saj.id
  }
  provisioner "local-exec" {
    command = <<EOT
az resource update \
  --ids "${azurerm_stream_analytics_job.saj.id}" \
  --api-version "2021-10-01-preview" \
  --set properties.subnetResourceId="${var.subnet_id}"
EOT
  }
  lifecycle {
    replace_triggered_by = [
      null_resource.saj.triggers
    ]
  }
  depends_on = [null_resource.update_stream_analytics_auth]
}

resource "null_resource" "update_query" {
  count = var.enable_private_access ? 1 : 0
  triggers = {
    saj_id = azurerm_stream_analytics_job.saj.id
  }
  provisioner "local-exec" {
    command = <<EOT
az stream-analytics transformation create \
  --resource-group ${azurerm_stream_analytics_job.saj.resource_group_name} \
  --job-name ${azurerm_stream_analytics_job.saj.name} \
  --name Transformation \
  --streaming-units ${var.streaming_units} \
  --saql "$(cat <<QUERY
${var.transformation_query}
QUERY
)"
EOT
  }
  lifecycle {
    replace_triggered_by = [
      null_resource.saj.triggers
    ]
  }
  depends_on = [null_resource.update_stream_analytics_subnet_config]
}


