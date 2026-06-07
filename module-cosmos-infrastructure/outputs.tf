output "cosmos_endpoint" {
  description = "The cosmos endpoint"
  value       = local.cosmos_endpoint
}

output "cosmos_primary_key" {
  description = "The cosmos primary key"
  value       = local.cosmos_primary_key
  sensitive   = true
}
