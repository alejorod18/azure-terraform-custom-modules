# =============================================================================
# Outputs — Key information from the provisioned infrastructure
# =============================================================================

# --- Networking ---

output "subnet_appservice_id" {
  description = "The ID of the App Service subnet."
  value       = module.subnet_appservice.subnet_id
}

output "subnet_private_endpoints_id" {
  description = "The ID of the Private Endpoints subnet."
  value       = module.subnet_private_endpoints.subnet_id
}

output "nat_gateway_ip" {
  description = "The public IP address of the NAT Gateway (App Service outbound)."
  value       = module.subnet_appservice.nat_gateway_ip
}

# --- Key Vault ---

output "keyvault_id" {
  description = "The Resource ID of the Key Vault."
  value       = module.keyvault.id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault."
  value       = module.keyvault.vault_uri
}

# --- Storage ---

output "storage_account_name" {
  description = "The name of the Storage Account."
  value       = module.storage.name
}

output "storage_blob_endpoint" {
  description = "The primary blob endpoint URL."
  value       = module.storage.blob_endpoint
}

# --- Cosmos DB ---

output "cosmos_endpoint" {
  description = "The endpoint URL for Cosmos DB."
  value       = module.cosmos.cosmos_endpoint
}

# --- Event Hubs ---

output "eventhub_namespace_name" {
  description = "The name of the Event Hub Namespace."
  value       = module.eventhubs.eventhub_namespace_name
}

# --- App Services ---

output "web_app_hostnames" {
  description = "Hostnames for each deployed Web App."
  value       = module.appservices.web_apps_hostnames
}
