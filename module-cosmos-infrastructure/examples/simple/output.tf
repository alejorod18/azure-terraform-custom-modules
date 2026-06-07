output "cosmos_endpoint" {
  value = module.cosmosdb_example.cosmos_endpoint
}

output "cosmos_primary_key" {
  value     = module.cosmosdb_example.cosmos_primary_key
  sensitive = true
}