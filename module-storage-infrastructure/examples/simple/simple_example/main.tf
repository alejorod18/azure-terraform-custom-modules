# Proveedor de Azure
provider "azurerm" {
  features {}
}

# Obtener información del Resource Group existente
data "azurerm_resource_group" "storage_resource_group" {
  name = var.resource_group_name
}

data "azurerm_subnet" "storage_subnet" {
  name                 = "example-subnet"
  resource_group_name  = data.azurerm_resource_group.storage_resource_group.name
  virtual_network_name = "example-vnet"
}

module "simple_storage_account" {
  source                     = "../../"
  resource_group_name        = data.azurerm_resource_group.storage_resource_group.name
  storage_account_name       = var.storage_account_name
  virtual_network_subnet_ids = [data.azurerm_subnet.storage_subnet.id]
  privateContainerNames      = ["wheels_libraries"]
}