locals {
  pe_private_dns_zone_name     = "privatelink.azconfig.io"
  pe_subresource_name          = "configurationStores"
  pe_with_existing_dns_zone    = { for pe in var.private_endpoints : pe.subnet_id => pe.existing_private_dns_zone_id if pe.existing_private_dns_zone_id != "" }
  pe_without_existing_dns_zone = { for pe in var.private_endpoints : pe.subnet_id => pe.existing_private_dns_zone_id if pe.existing_private_dns_zone_id == "" }
}

module "private_endpoints_with_existing_dns_zone" {
  source                       = "../module-private-endpoints-infrastructure"
  for_each                     = local.pe_with_existing_dns_zone
  resource_group_name          = var.resource_group_name
  identifier                   = "${var.identifier}-${element(split("/", each.key), length(split("/", each.key)) - 1)}"
  subnet_id                    = each.key
  resource_id                  = azurerm_app_configuration.appconf.id
  private_dns_zone_name        = local.pe_private_dns_zone_name
  subresource_name             = local.pe_subresource_name
  existing_private_dns_zone_id = each.value
}


resource "azurerm_private_dns_zone" "dns" {
  count               = length(local.pe_without_existing_dns_zone) > 1 ? 1 : 0
  name                = local.pe_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = data.azurerm_resource_group.rg.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns" {
  for_each              = (length(local.pe_without_existing_dns_zone) > 1) ? local.pe_without_existing_dns_zone : {}
  name                  = "${var.identifier}-${element(split("/", each.key), length(split("/", each.key)) - 1)}-dns"
  private_dns_zone_name = azurerm_private_dns_zone.dns[0].name
  virtual_network_id    = join("/", slice(split("/", each.key), 0, 9))
  resource_group_name   = data.azurerm_resource_group.rg.name
  tags                  = data.azurerm_resource_group.rg.tags
}

locals {
  private_dns_zone_id = length(local.pe_without_existing_dns_zone) > 1 ? join("/", [
    "/subscriptions",
    data.azurerm_client_config.current.subscription_id,
    "resourceGroups",
    data.azurerm_resource_group.rg.name,
    "providers",
    "Microsoft.Network",
    "privateDnsZones",
    local.pe_private_dns_zone_name
  ]) : ""
}

module "private_endpoints_without_existing_dns_zone" {
  source                       = "../module-private-endpoints-infrastructure"
  for_each                     = local.pe_without_existing_dns_zone
  resource_group_name          = var.resource_group_name
  identifier                   = "${var.identifier}-${element(split("/", each.key), length(split("/", each.key)) - 1)}"
  subnet_id                    = each.key
  resource_id                  = azurerm_app_configuration.appconf.id
  private_dns_zone_name        = local.pe_private_dns_zone_name
  subresource_name             = local.pe_subresource_name
  existing_private_dns_zone_id = length(local.pe_without_existing_dns_zone) > 1 ? local.private_dns_zone_id : ""
}