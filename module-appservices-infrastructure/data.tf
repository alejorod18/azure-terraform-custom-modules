data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "http" "my_public_ip" {
  url = "http://checkip.amazonaws.com"
}

data "azurerm_user_assigned_identity" "mi" {
  name                = var.managed_identity_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

