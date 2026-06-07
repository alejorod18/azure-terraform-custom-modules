# =============================================================================
# Complete Example: Multi-Module Azure Infrastructure Stack
# =============================================================================
#
# This example provisions a production-ready stack with:
# - Networking (subnets + NAT gateway)
# - Key Vault (secrets management)
# - Storage Account (blob storage)
# - Cosmos DB (NoSQL database)
# - Event Hubs (event streaming)
# - App Services (web apps + functions)
# - Private Endpoints (secure data plane access)
#
# Prerequisites:
#   - An existing Resource Group
#   - An existing Virtual Network
#   - A Log Analytics Workspace
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

# Managed Identity for App Services
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.identifier}-app"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = var.resource_group_name
}

# =============================================================================
# 1. NETWORKING — Subnets
# =============================================================================

module "subnet_appservice" {
  source = "../../module-networks-infrastructure"

  resource_group_name                    = var.resource_group_name
  virtual_network_name                   = var.virtual_network_name
  identifier                             = "${var.identifier}-appservice"
  subnet_address_prefix                  = var.subnet_appservice_prefix
  enable_app_service_delegation          = true
  enable_containers_delegation           = false
  enable_stream_analytics_job_delegation = false
  enable_nat_gateway                     = true
  enable_service_endpoints               = true
}

module "subnet_private_endpoints" {
  source = "../../module-networks-infrastructure"

  resource_group_name                      = var.resource_group_name
  virtual_network_name                     = var.virtual_network_name
  identifier                               = "${var.identifier}-pe"
  subnet_address_prefix                    = var.subnet_private_endpoints_prefix
  enable_app_service_delegation            = false
  enable_containers_delegation             = false
  enable_stream_analytics_job_delegation   = false
  enable_nat_gateway                       = false
  enable_service_endpoints                 = false
  enable_private_endpoint_network_policies = true
}

# =============================================================================
# 2. KEY VAULT — Secrets Management
# =============================================================================

module "keyvault" {
  source = "../../module-secrets-infrastructure"

  resource_group_name        = var.resource_group_name
  identifier                 = var.identifier
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enable_public_access       = false

  subnets_id_whitelist = [module.subnet_appservice.subnet_id]
  ip_range_whitelist   = []

  environment_secrets = {
    "DATABASE-CONNECTION-STRING" = "placeholder-update-after-deploy"
    "STORAGE-CONNECTION-STRING"  = "placeholder-update-after-deploy"
    "APP-INSIGHTS-KEY"           = "placeholder-update-after-deploy"
  }

  access_policies = []

  private_endpoints = [
    {
      subnet_id                    = module.subnet_private_endpoints.subnet_id
      existing_private_dns_zone_id = ""
    }
  ]
}

# =============================================================================
# 3. STORAGE — Blob Storage
# =============================================================================

module "storage" {
  source = "../../module-storage-infrastructure"

  resource_group_name = var.resource_group_name
  identifier          = var.identifier
  containers = { for c in var.storage_containers : c => {} }

  subnets_id_whitelist = [module.subnet_appservice.subnet_id]
  ip_range_whitelist   = []
  enable_public_access = false
}

# Private Endpoint for Storage
module "pe_storage" {
  source = "../../module-private-endpoints-infrastructure"

  resource_group_name   = var.resource_group_name
  subnet_id             = module.subnet_private_endpoints.subnet_id
  resource_id           = module.storage.name
  identifier            = "${var.identifier}-storage"
  private_dns_zone_name = "privatelink.blob.core.windows.net"
  subresource_name      = "blob"
}

# =============================================================================
# 4. COSMOS DB — NoSQL Database
# =============================================================================

module "cosmos" {
  source = "../../module-cosmos-infrastructure"

  resource_group_name        = var.resource_group_name
  identifier                 = var.identifier
  log_analytics_workspace_id = var.log_analytics_workspace_id

  ip_range_whitelist   = []
  subnets_id_whitelist = [module.subnet_appservice.subnet_id]

  sql_databases = var.cosmos_databases

  private_endpoints = [
    {
      subnet_id                    = module.subnet_private_endpoints.subnet_id
      existing_private_dns_zone_id = ""
    }
  ]
}

# =============================================================================
# 5. EVENT HUBS — Event Streaming
# =============================================================================

module "eventhubs" {
  source = "../../module-events-hubs-infrastructure"

  resource_group_name      = var.resource_group_name
  identifier               = var.identifier
  sku                      = "Standard"
  capacity                 = 1
  auto_inflate_enabled     = true
  maximum_throughput_units = 4

  subnets_id_whitelist = [module.subnet_appservice.subnet_id]
  ip_range_whitelist   = []

  event_hubs = var.event_hubs
}

# =============================================================================
# 6. APP SERVICES — Web Applications
# =============================================================================

module "appservices" {
  source = "../../module-appservices-infrastructure"

  resource_group_name        = var.resource_group_name
  identifier                 = var.identifier
  sku_name                   = var.app_service_sku
  managed_identity_name      = azurerm_user_assigned_identity.app.name
  subnet_id                  = module.subnet_appservice.subnet_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  zone_balancing_enabled     = false
  enable_slot                = true

  ip_range_whitelist       = []
  subnets_id_whitelist     = []
  scm_ip_range_whitelist   = []
  scm_subnets_id_whitelist = []

  # Secrets from Key Vault will be available as app settings
  key_vault_secrets = module.keyvault.secrets

  app_service_web_apps = {
    "api" = {
      app_settings = {
        "COSMOS_ENDPOINT"       = module.cosmos.cosmos_endpoint
        "EVENTHUB_NAMESPACE"    = module.eventhubs.eventhub_namespace_name
        "STORAGE_BLOB_ENDPOINT" = module.storage.blob_endpoint
      }
    }
    "admin" = {
      app_settings = {
        "COSMOS_ENDPOINT" = module.cosmos.cosmos_endpoint
      }
    }
  }

  app_service_function_apps = {}
}

# =============================================================================
# 7. APP CONFIGURATION (Optional) — Feature Flags & Config
# =============================================================================

# Uncomment to add centralized application configuration:
#
# module "app_configuration" {
#   source = "../../module-app-configuration-infrastructure"
#
#   resource_group_name        = var.resource_group_name
#   identifier                 = var.identifier
#   log_analytics_workspace_id = var.log_analytics_workspace_id
#   enable_public_access       = false
#
#   variables = {
#     "FeatureFlags/DarkMode"  = "true"
#     "FeatureFlags/BetaUsers" = "false"
#     "Config/MaxRetries"      = "3"
#   }
#
#   secrets = {}
#
#   private_endpoints = {
#     "appconfig" = {
#       subnet_id             = module.subnet_private_endpoints.subnet_id
#       private_dns_zone_name = "privatelink.azconfig.io"
#       subresource_name      = "configurationStores"
#     }
#   }
# }
