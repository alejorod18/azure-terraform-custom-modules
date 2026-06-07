data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "http" "my_public_ip" {
  url = "http://checkip.amazonaws.com"
}

data "azurerm_client_config" "current" {}

data "azurerm_user_assigned_identity" "keyvault_mi" {
  name                = var.keyvault_managed_identity_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_user_assigned_identity" "reader_mi" {
  name                = var.reader_managed_identity_name
  resource_group_name = data.azurerm_resource_group.rg.name
}