resource "azurerm_user_assigned_identity" "example" {
  name                = "mi-example-continer-apps"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  tags                = data.azurerm_resource_group.example.tags
}

data "azurerm_container_registry" "acr" {
  name                = "acrcommonAcrsadmdev"
  resource_group_name = "rg-commonAcrs-adm-dev"
}

resource "azurerm_role_assignment" "acr" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}
