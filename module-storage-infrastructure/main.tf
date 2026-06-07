locals {
  enable_public_access = var.enable_public_access ? "Allow" : "Deny"
}

resource "azurerm_storage_account" "storage" {
  name                = "${var.identifier}${data.azurerm_resource_group.rg.tags.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = data.azurerm_resource_group.rg.tags

  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = local.account_replication_type

  https_traffic_only_enabled = var.enable_https_traffic_only
  is_hns_enabled             = var.is_hns_enabled
  min_tls_version            = var.min_tls_version

  access_tier              = var.account_tier == "Premium" ? null : "Hot"
  large_file_share_enabled = var.large_file_share_enabled

  network_rules {
    default_action             = local.enable_public_access
    bypass                     = ["Metrics", "AzureServices"]
    ip_rules                   = local.users_ip_range_whitelist
    virtual_network_subnet_ids = var.subnets_id_whitelist
  }
}

resource "azurerm_storage_container" "containers" {
  for_each              = var.containers
  name                  = each.key
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = each.value.enable_public_access ? "public" : "private"
}

#
# resource "azurerm_storage_table" "table" {
#   for_each = var.tables
#   name                 = each.key
#   storage_account_name = azurerm_storage_account.storage.name
# }
#
# resource "azurerm_storage_share" "file_share" {
#   name                 = "examplefileshare"
#   storage_account_name = azurerm_storage_account.storage.name
#   quota               = 5120
#   access_tier         = "TransactionOptimized"
#   metadata = {
#     usage = "backup"
#   }
# }
#
# resource "azurerm_storage_queue" "queue" {
#   name                 = "examplequeue"
#   storage_account_name = azurerm_storage_account.storage.name
#   metadata = {
#     purpose = "messaging"
#   }
# }
