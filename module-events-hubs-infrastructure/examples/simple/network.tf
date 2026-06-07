resource "azurerm_subnet" "subnet" {
  name                 = "example-subnet"
  resource_group_name  = "rg-networking-dev"
  virtual_network_name = "vnet-adm-dev-eastus-013"
  address_prefixes     = ["10.3.41.0/24"]
  service_endpoints    = ["Microsoft.EventHub"]
  delegation {
    name = "delegacion-web"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.App/environments"
    }
  }
}
