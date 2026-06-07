provider "azurerm" {
  features {}
  subscription_id = "<your-azure-subscription-id>"
}

data "azurerm_virtual_network" "example" {
  resource_group_name = "rg-networking-qas"
  name                = "vnet-data-qas-eastus-003"
}

output "dns_servers" {
  value = data.azurerm_virtual_network.example.dns_servers
}


# resource "azurerm_subnet" "private_endpoint" {
#   address_prefixes = ["10.2.14.136/29"]
#   name                 = "acr-pe-example"
#   resource_group_name  = "rg-networking-qas"
#   virtual_network_name = "vnet-data-qas-eastus-003"
# }
#
# module "private_endpoint_example" {
#   source                = "../../"
#   resource_group_name = "rg-networking-dev"
#   subnet_id             = azurerm_subnet.private_endpoint.id
#   resource_id           = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-commonAcrs-data-qas/providers/Microsoft.ContainerRegistry/registries/acrcommonAcrsdataqas"
#   identifier            = "acr-connection"
#   private_dns_zone_name = "privatelink.azurecr.io"
#   subresource_name      = "registry"
# }
