provider "azurerm" {
  features {}
  subscription_id = "<your-azure-subscription-id>"
}

module "private_endpoint_example" {
  source              = "../../"
  resource_group_name = "rg-migracioncore-tech-dev"
  subnet_id           = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-qas/providers/Microsoft.Network/virtualNetworks/vnet-adm-qas-eastus-015/subnets/snet-migracioncore"
  resource_id         = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-migracioncore-tech-dev/providers/Microsoft.Synapse/workspaces/asworkspace-migracioncore-tech-dev"
  identifier          = "migracioncore"
  subresource_name    = "Dev"
}
