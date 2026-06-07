resource "random_password" "administrator_login_password" {
  length           = var.passwords_length
  special          = true
  override_special = var.passwords_special_characters
}

resource "azurerm_cosmosdb_postgresql_cluster" "sql" {
  name                                 = lower("cosmos-pgsql-${var.identifier}")
  resource_group_name                  = data.azurerm_resource_group.rg.name
  tags                                 = data.azurerm_resource_group.rg.tags
  location                             = data.azurerm_resource_group.rg.location
  citus_version                        = var.citus_version
  administrator_login_password         = random_password.administrator_login_password.result
  coordinator_vcore_count              = var.coordinator_vcore_count
  coordinator_storage_quota_in_mb      = var.coordinator_storage_quota_in_mb
  coordinator_public_ip_access_enabled = var.enable_public_access
  node_count                           = var.node_count
  node_public_ip_access_enabled        = var.enable_public_access
  node_server_edition                  = var.node_server_edition
  node_vcores                          = var.node_vcores
  node_storage_quota_in_mb             = var.node_storage_quota_in_mb
  ha_enabled                           = local.ha_enabled
  preferred_primary_zone               = var.preferred_primary_zone
  shards_on_coordinator_enabled        = var.shards_on_coordinator_enabled
  sql_version                          = var.sql_version
  maintenance_window {
    day_of_week  = var.maintenance_window.day_of_week
    start_hour   = var.maintenance_window.start_hour
    start_minute = var.maintenance_window.start_minute
  }
}

resource "azurerm_cosmosdb_postgresql_coordinator_configuration" "coordinator_configuration" {
  for_each   = var.coordinator_configuration
  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.sql.id
  value      = each.value
}

resource "azurerm_cosmosdb_postgresql_node_configuration" "node_configuration" {
  for_each   = var.node_configuration
  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.sql.id
  value      = each.value
}

resource "azurerm_cosmosdb_postgresql_firewall_rule" "rules" {
  for_each = {
    for ip in local.users_ip_range_whitelist : ip => {
      name             = "firewallrule-${replace(replace(ip, ".", "-"), "/", "-")}-ip"
      start_ip_address = length(regexall("/32$", ip)) > 0 ? element(split("/", ip), 0) : cidrhost(ip, 1)
      end_ip_address   = length(regexall("/32$", ip)) > 0 ? element(split("/", ip), 0) : cidrhost(ip, pow(2, (32 - tonumber(element(split("/", ip), 1)))) - 2)
    }
  }
  name             = each.value.name
  cluster_id       = azurerm_cosmosdb_postgresql_cluster.sql.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "random_password" "roles_passwords" {
  for_each         = var.users_names_list
  length           = var.passwords_length
  special          = true
  override_special = var.passwords_special_characters
}

resource "azurerm_cosmosdb_postgresql_role" "roles" {
  for_each   = var.users_names_list
  name       = each.key
  cluster_id = azurerm_cosmosdb_postgresql_cluster.sql.id
  password   = random_password.roles_passwords[each.key].result
}