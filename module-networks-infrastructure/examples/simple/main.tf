# Example usage of the module
provider "azurerm" {
  features {}
}

module "subnet" {
  source                                 = "../../"
  resource_group_name                    = "rg-networking"
  enable_app_service_delegation          = false
  enable_stream_analytics_job_delegation = false
  enable_containers_delegation           = true
  enable_nat_gateway                     = true
  enable_service_endpoints               = true
  identifier                             = "example"
  virtual_network_name                   = "vnet-data-qas-eastus-003"
  subnet_address_prefix                  = "10.2.14.136/29"
}