data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "http" "my_public_ip" {
  url = "http://checkip.amazonaws.com"
}

data "azurerm_cosmosdb_account" "cosmosdb" {
  count               = !var.create_cosmosdb ? 1 : 0
  name                = var.identifier
  resource_group_name = var.resource_group_name
}


data "azurerm_client_config" "current" {}
