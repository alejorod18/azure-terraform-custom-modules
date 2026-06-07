provider "azurerm" {
  features {}
  subscription_id = "<your-azure-subscription-id>"
}

module "private_endpoint_example" {
  resource_group_name   = "rg-networking-dev"
  source                = "../../"
  subnet_id             = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-adm-dev-eastus-008/subnets/snet-pe-sap-adm-dev"
  resource_id           = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-custom-infra-adm-dev/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-custom-infra-adm-dev"
  identifier            = "cosmos-connection"
  private_dns_zone_name = "privatelink.documents.azure.com"
  subresource_name      = "Sql"
}

