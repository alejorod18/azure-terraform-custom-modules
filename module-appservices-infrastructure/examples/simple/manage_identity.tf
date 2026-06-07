resource "azurerm_user_assigned_identity" "example" {
  name                = "mi-example"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  tags                = data.azurerm_resource_group.example.tags
}

resource "azurerm_role_assignment" "acr" {
  scope                = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-commonAcrs-adm-dev/providers/Microsoft.ContainerRegistry/registries/acrcommonAcrsadmdev"
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}
