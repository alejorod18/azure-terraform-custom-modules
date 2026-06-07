data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "sa" {
  count               = local.enable_existing_storage_account_backup ? 1 : 0
  name                = var.capture_storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_container" "container" {
  count                = local.enable_existing_storage_account_backup ? 1 : 0
  name                 = var.capture_storage_account_container_name
  storage_account_name = data.azurerm_storage_account.sa[0].name
}

data "http" "my_public_ip" {
  url = "http://checkip.amazonaws.com"
}

data "azurerm_client_config" "current" {}
