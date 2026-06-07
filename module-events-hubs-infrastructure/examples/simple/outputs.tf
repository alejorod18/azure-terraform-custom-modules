output "connection_strings" {
  value     = module.eventhub_module.connection_strings
  sensitive = true
}

output "eventhub_namespace_name" {
  value = module.eventhub_module.eventhub_namespace_name
}

output "eventhub_namespace_id" {
  value = module.eventhub_module.eventhub_namespace_id
}

output "consumer_groups" {
  value = module.eventhub_module.consumer_groups
}