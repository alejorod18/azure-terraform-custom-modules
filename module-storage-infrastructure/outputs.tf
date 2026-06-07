output "connection_string" {
  value = azurerm_storage_account.storage.primary_connection_string
}

output "blob_endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "name" {
  value = azurerm_storage_account.storage.name
}

output "access_key" {
  value = azurerm_storage_account.storage.primary_access_key
}
