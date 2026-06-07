
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the resource will be created."
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "identifier" {
  type        = string
  description = "Unique identifier for the resource."
  validation {
    condition     = length(var.identifier) >= 3 && length(var.identifier) <= 44
    error_message = "The identifier must be between 3 and 44 characters long."
  }
}

variable "ip_range_whitelist" {
  type        = list(string)
  description = "List of IP addresses that will have access to the resource."
  default     = []
  validation {
    condition = var.ip_range_whitelist == [] || alltrue([
      for ip in var.ip_range_whitelist : can(regex(
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/(3[0-2]|[12]?[0-9])$",
        ip
      ))
    ])
    error_message = "Todos los elementos en ip_range_whitelist deben ser direcciones IP válidas o rangos en notación CIDR."
  }
}

variable "subnets_id_whitelist" {
  type        = list(string)
  description = "List of subnet IDs that will have access to the resource."
  default     = []
  validation {
    condition     = var.subnets_id_whitelist == [] || alltrue([for id in var.subnets_id_whitelist : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", id))])
    error_message = "Each subnet ID must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

variable "active_drp_as_primary" {
  type        = bool
  description = "Indicates if the resource is in an active DRP."
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID of the Log Analytics workspace."
  default     = ""
  validation {
    condition     = var.log_analytics_workspace_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "The log_analytics_workspace_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
  }
}

variable "private_endpoints" {
  type = list(object(
    {
      subnet_id                    = string
      existing_private_dns_zone_id = optional(string, "")
    }
  ))
  description = "List of private endpoints configurations."
  default     = []
}

variable "sql_databases" {
  type = map(map(object({
    partition_key_paths = list(string)
    excluded_paths      = optional(list(string))
    max_throughput      = optional(number)
  })))
  description = "List of databases to create in CosmosDB."
  default     = {}
}

variable "create_cosmosdb" {
  type        = bool
  description = "Indicates if the CosmosDB account should be created."
  default     = true
}

variable "database_creation_excluded_list" {
  type        = list(string)
  description = "List of databases that should not be created."
  default     = []
}

locals {
  cosmos_id                  = var.create_cosmosdb ? azurerm_cosmosdb_account.cosmos[0].id : data.azurerm_cosmosdb_account.cosmosdb[0].id
  cosmos_endpoint            = var.create_cosmosdb ? azurerm_cosmosdb_account.cosmos[0].endpoint : data.azurerm_cosmosdb_account.cosmosdb[0].endpoint
  cosmos_primary_key         = var.create_cosmosdb ? azurerm_cosmosdb_account.cosmos[0].primary_key : data.azurerm_cosmosdb_account.cosmosdb[0].primary_key
  cosmos_name                = var.create_cosmosdb ? azurerm_cosmosdb_account.cosmos[0].name : data.azurerm_cosmosdb_account.cosmosdb[0].name
  cosmos_resource_group_name = var.create_cosmosdb ? azurerm_cosmosdb_account.cosmos[0].resource_group_name : data.azurerm_cosmosdb_account.cosmosdb[0].resource_group_name
  its_production             = data.azurerm_resource_group.rg.tags.environment != "qas" && data.azurerm_resource_group.rg.tags.environment != "dev"
  environment                = data.azurerm_resource_group.rg.tags.environment
  redundancy                 = local.environment != "qas" && data.azurerm_resource_group.rg.location == "eastus"
  drp_its_ok                 = local.environment == "prd" && data.azurerm_resource_group.rg.location == "eastus"
  drp_location               = "westus"
  flattened_sql_containers = var.sql_databases == [] ? [] : flatten([
    for db_name, containers in var.sql_databases : [
      for container_name, properties in containers : {
        database_name       = db_name
        container_name      = container_name
        partition_key_paths = lookup(properties, "partition_key_paths", [])
        excluded_paths      = lookup(properties, "excluded_paths", [])
        max_throughput      = lookup(properties, "max_throughput", data.azurerm_resource_group.rg.tags.environment == "prd" ? 10000 : 4000)
      }
    ]
  ])
  databases_to_create      = toset([for db, content in var.sql_databases : db if !contains(var.database_creation_excluded_list, db)])
  users_ip_range_whitelist = concat(var.ip_range_whitelist, local.default_ip_ranges_list, [local.executor_public_ip])
  executor_public_ip       = "${trimspace(data.http.my_public_ip.response_body)}/32"
  default_ip_ranges_list   = []
}
