# Schema Registry Group
resource "azurerm_eventhub_namespace_schema_group" "sg" {
  for_each             = var.schema_groups
  name                 = "sg-${each.key}-${var.identifier}"
  namespace_id         = azurerm_eventhub_namespace.ns.id
  schema_compatibility = each.value.compatibility
  schema_type          = each.value.type
}
