output "connection_strings" {
  value     = local.eventhub_connection_strings
  sensitive = true
}

output "primary_keys" {
  value     = local.eventhub_primary_keys
  sensitive = true
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.ns.name
}

output "eventhub_namespace_id" {
  value = azurerm_eventhub_namespace.ns.id
}

output "consumer_groups" {
  value = {
    for eh, content in var.event_hubs : eh => content.consumer_groups if length(content.consumer_groups) > 0
  }
}