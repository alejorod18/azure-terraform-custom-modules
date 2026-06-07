resource "azurerm_role_assignment" "rg" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = data.azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "container_app_rg" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Container Apps Operator"
  principal_id         = data.azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "container_app" {
  for_each             = azurerm_container_app.container_app
  scope                = each.value.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.mi.principal_id
}
