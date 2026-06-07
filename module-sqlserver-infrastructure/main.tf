resource "random_password" "administrator_login_password" {
  length           = var.passwords_length
  special          = true
  override_special = var.passwords_special_characters
}

resource "azurerm_mssql_server" "primary" {
  name                         = local.its_production ? "mssql-${var.identifier}-primary" : "mssql-${var.identifier}"
  tags                         = data.azurerm_resource_group.rg.tags
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.administrator_login_password.result

  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  timeouts {
    create = "60m"
    update = "60m"
    read   = "5m"
    delete = "60"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_server" "secondary" {
  name                          = "mssqlserver-primary"
  tags                          = data.azurerm_resource_group.rg.tags
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = "sqladmin"
  administrator_login_password  = random_password.administrator_login_password.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  timeouts {
    create = "60m"
    update = "60m"
    read   = "5m"
    delete = "60"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_database" "primary" {
  name               = "example-db"
  tags               = data.azurerm_resource_group.rg.tags
  server_id          = azurerm_mssql_server.primary.id
  collation          = "SQL_Latin1_General_CP1_CI_AS"
  license_type       = "LicenseIncluded"
  max_size_gb        = 4
  sku_name           = "S0"
  zone_redundant     = true
  secondary_type     = "Geo"
  geo_backup_enabled = true
  ledger_enabled     = true # True in DRP and PRD
  long_term_retention_policy {
    weekly_retention          = "P3M"
    monthly_retention         = "P1Y"
    yearly_retention          = "P3Y"
    week_of_year              = 52
    immutable_backups_enabled = false
  }
  short_term_retention_policy {
    retention_days           = 30
    backup_interval_in_hours = 12
  }

  read_replica_count = 1    # Initial count
  read_scale         = true # True in DRP and PRD

  enclave_type = "VBS"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_database" "secondary" {
  name               = "example-db"
  tags               = data.azurerm_resource_group.rg.tags
  server_id          = azurerm_mssql_server.secondary.id
  collation          = "SQL_Latin1_General_CP1_CI_AS"
  license_type       = "LicenseIncluded"
  max_size_gb        = 4
  sku_name           = "S0"
  zone_redundant     = true
  secondary_type     = "Geo"
  geo_backup_enabled = true
  ledger_enabled     = true # True in DRP and PRD
  long_term_retention_policy {
    weekly_retention          = "P3M"
    monthly_retention         = "P1Y"
    yearly_retention          = "P3Y"
    week_of_year              = 52
    immutable_backups_enabled = false
  }
  short_term_retention_policy {
    retention_days           = 30
    backup_interval_in_hours = 12
  }

  read_replica_count = 1    # Initial count
  read_scale         = true # True in DRP and PRD

  enclave_type = "VBS"
  lifecycle {
    prevent_destroy = true
  }
  create_mode = "OnlineSecondary" # If DRP
}

resource "azurerm_mssql_failover_group" "drp" {
  name      = "example"
  tags      = data.azurerm_resource_group.rg.tags
  server_id = azurerm_mssql_server.primary.id
  databases = [
    azurerm_mssql_database.primary.id
  ]

  partner_server {
    id = azurerm_mssql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode = "Manual"
  }
  timeouts {
    create = "60m"
    update = "60m"
    read   = "5m"
    delete = "60"
  }
}


resource "azurerm_mssql_firewall_rule" "primary" {
  for_each         = local.calculated_ip_starts_and_ends
  server_id        = azurerm_mssql_server.primary.id
  name             = each.value.name
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_firewall_rule" "secondary" {
  for_each         = local.calculated_ip_starts_and_ends
  server_id        = azurerm_mssql_server.secondary.id
  name             = each.value.name
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}