resource "azurerm_cosmosdb_account" "cosmos" {
  count                             = var.create_cosmosdb ? 1 : 0
  name                              = "cosmos-${lower(replace(var.identifier, "_", "-"))}"
  tags                              = data.azurerm_resource_group.rg.tags
  resource_group_name               = data.azurerm_resource_group.rg.name
  location                          = data.azurerm_resource_group.rg.location
  offer_type                        = "Standard"
  kind                              = "GlobalDocumentDB"
  free_tier_enabled                 = true
  automatic_failover_enabled        = true
  public_network_access_enabled     = true
  is_virtual_network_filter_enabled = true
  ip_range_filter                   = local.users_ip_range_whitelist

  dynamic "virtual_network_rule" {
    for_each = var.subnets_id_whitelist
    content { id = virtual_network_rule.value }
  }

  backup {
    type = "Continuous"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 60 * 15
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = data.azurerm_resource_group.rg.location
    failover_priority = var.active_drp_as_primary && local.drp_its_ok ? 1 : 0
    zone_redundant    = local.redundancy
  }

  dynamic "geo_location" {
    for_each = local.drp_its_ok ? [1] : []
    content {
      location          = local.drp_location
      failover_priority = var.active_drp_as_primary ? 0 : 1
      zone_redundant    = local.redundancy
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "sql_database" {
  for_each            = local.databases_to_create
  name                = each.key
  resource_group_name = local.cosmos_resource_group_name
  account_name        = local.cosmos_name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  for_each              = { for container in local.flattened_sql_containers : "${container.database_name}-${container.container_name}" => container }
  name                  = each.value.container_name
  resource_group_name   = local.cosmos_resource_group_name
  database_name         = each.value.database_name
  partition_key_paths   = each.value.partition_key_paths
  account_name          = local.cosmos_name
  partition_key_version = 2

  conflict_resolution_policy {
    mode                     = "LastWriterWins"
    conflict_resolution_path = "/_ts"
  }

  dynamic "autoscale_settings" {
    for_each = local.its_production ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }

  indexing_policy {
    indexing_mode = "consistent"
    included_path {
      path = "/*"
    }
    dynamic "excluded_path" {
      for_each = toset(coalesce(each.value.excluded_paths, []))
      content {
        path = excluded_path.key
      }
    }
  }
  depends_on = [azurerm_cosmosdb_sql_database.sql_database]
}
