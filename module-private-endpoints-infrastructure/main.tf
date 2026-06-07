resource "azurerm_private_dns_zone" "dns" {
  count               = var.existing_private_dns_zone_id == "" && var.private_dns_zone_name != "" ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.resource.name
  tags                = data.azurerm_resource_group.resource.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns" {
  count                 = var.existing_private_dns_zone_id == "" && var.private_dns_zone_name != "" ? 1 : 0
  name                  = "${var.identifier}-dns"
  private_dns_zone_name = azurerm_private_dns_zone.dns[0].name
  virtual_network_id    = local.vnet_id
  resource_group_name   = data.azurerm_resource_group.resource.name
  tags                  = data.azurerm_resource_group.resource.tags
}

resource "azurerm_private_endpoint" "pe" {
  location            = data.azurerm_resource_group.resource.location
  name                = "pe-${var.identifier}"
  resource_group_name = data.azurerm_resource_group.resource.name
  subnet_id           = var.subnet_id
  tags                = data.azurerm_resource_group.resource.tags

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_name != "" || var.existing_private_dns_zone_id != "" ? [1] : []
    content {
      name = "${var.identifier}-dns-zone-group"
      private_dns_zone_ids = [
        local.private_dns_id
      ]
    }
  }

  private_service_connection {
    name                           = "${var.identifier}-private-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = var.resource_id
    subresource_names              = [var.subresource_name]
  }
  lifecycle {
    ignore_changes = [
      location, tags
    ]
  }
}
