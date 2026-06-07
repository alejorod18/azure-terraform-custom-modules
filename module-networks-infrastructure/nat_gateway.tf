resource "azurerm_public_ip" "net" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "pip-${var.identifier}"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "net" {
  count                   = var.enable_nat_gateway ? 1 : 0
  name                    = "ngw-${var.identifier}"
  location                = local.location
  resource_group_name     = data.azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_nat_gateway_public_ip_association" "project" {
  count                = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.net[0].id
  public_ip_address_id = azurerm_public_ip.net[0].id
}

resource "azurerm_subnet_nat_gateway_association" "project" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.net.id
  nat_gateway_id = azurerm_nat_gateway.net[0].id
}

resource "azurerm_route_table" "project" {
  count                         = var.enable_nat_gateway ? 1 : 0
  name                          = "route-${var.identifier}"
  location                      = data.azurerm_resource_group.rg.location
  resource_group_name           = azurerm_subnet.net.resource_group_name
  bgp_route_propagation_enabled = false

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_subnet_route_table_association" "project" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.net.id
  route_table_id = azurerm_route_table.project[0].id
}

