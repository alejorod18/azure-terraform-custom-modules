output "id" {
  value       = azurerm_app_configuration.appconf.id
  description = "The unique identifier for the Azure App Configuration resource."
}

output "name" {
  value       = azurerm_app_configuration.appconf.name
  description = "The name of the Azure App Configuration resource."
}

output "location" {
  value       = azurerm_app_configuration.appconf.location
  description = "The location where the Azure App Configuration resource is deployed."
}

output "sku" {
  value       = azurerm_app_configuration.appconf.sku
  description = "The SKU associated with the Azure App Configuration resource."
}

output "identity" {
  value       = azurerm_app_configuration.appconf.identity
  description = "The identity assigned to the resource, either system-assigned or user-assigned."
}

output "replica" {
  value       = azurerm_app_configuration.appconf.replica
  description = "Details of the replicas configured for the Azure App Configuration resource."
}

output "purge_protection_enabled" {
  value       = azurerm_app_configuration.appconf.purge_protection_enabled
  description = "Indicates whether purge protection is enabled for the resource."
}

output "soft_delete_retention_days" {
  value       = azurerm_app_configuration.appconf.soft_delete_retention_days
  description = "The number of days soft-deleted data will remain in the deleted state."
}

output "local_auth_enabled" {
  value       = azurerm_app_configuration.appconf.local_auth_enabled
  description = "Indicates whether local authentication is enabled for the resource."
}

output "public_network_access" {
  value       = azurerm_app_configuration.appconf.public_network_access
  description = "Specifies the public network access setting for the resource."
}

output "primary_read_key" {
  value       = length(azurerm_app_configuration.appconf.primary_read_key) > 0 ? azurerm_app_configuration.appconf.primary_read_key[0].connection_string : ""
  description = "The connection string for the primary read-only key of the resource."
  sensitive   = true
}

output "primary_write_key" {
  value       = length(azurerm_app_configuration.appconf.primary_write_key) > 0 ? azurerm_app_configuration.appconf.primary_write_key[0].connection_string : ""
  description = "The connection string for the primary write key of the resource."
  sensitive   = true
}

output "secondary_read_key" {
  value       = length(azurerm_app_configuration.appconf.secondary_read_key) > 0 ? azurerm_app_configuration.appconf.secondary_read_key[0].connection_string : ""
  description = "The connection string for the secondary read-only key of the resource."
  sensitive   = true
}

output "secondary_write_key" {
  value       = length(azurerm_app_configuration.appconf.secondary_write_key) > 0 ? azurerm_app_configuration.appconf.secondary_write_key[0].connection_string : ""
  description = "The connection string for the secondary write key of the resource."
  sensitive   = true
}

output "endpoint" {
  value       = azurerm_app_configuration.appconf.endpoint
  description = "The endpoint for the Azure App Configuration resource."
}