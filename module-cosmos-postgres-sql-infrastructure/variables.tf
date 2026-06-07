
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

variable "coordinator_configuration" {
  type        = map(string)
  description = "Map of coordinator configurations."
  default     = {}
}

variable "node_configuration" {
  type        = map(string)
  description = "Map of node configurations."
  default     = {}
}

variable "users_names_list" {
  type        = set(string)
  description = "List of users."
  default     = []
}

variable "passwords_length" {
  type        = number
  description = "Length of the passwords."
  default     = 16
}

variable "passwords_special_characters" {
  type        = string
  description = "Special characters to include in the passwords."
  default     = "!@#$*"
}

variable "citus_version" {
  type        = string
  description = "Citus version."
  default     = "12.1"
}

variable "coordinator_vcore_count" {
  type        = number
  description = "Number of vCores for the coordinator."
  default     = 2
}

variable "coordinator_storage_quota_in_mb" {
  type        = number
  description = "Storage quota in MB for the coordinator."
  default     = 131072
}

variable "node_count" {
  type        = number
  description = "Number of nodes."
  default     = 0
}

variable "enable_public_access" {
  type    = bool
  default = false
}

variable "node_server_edition" {
  type        = string
  description = "Server edition for the nodes."
  default     = "GeneralPurpose"
}

variable "node_vcores" {
  type        = number
  description = "Number of vCores for the nodes."
  default     = 2
}

variable "node_storage_quota_in_mb" {
  type        = number
  description = "Storage quota in MB for the nodes."
  default     = 524288
}

variable "shards_on_coordinator_enabled" {
  type        = bool
  description = "Indicates if the coordinator will have shards."
  default     = false
}

variable "sql_version" {
  type        = string
  description = "SQL version."
  default     = "16"
}

variable "preferred_primary_zone" {
  type        = string
  description = "Preferred primary zone."
  default     = null
}

variable "maintenance_window" {
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  description = "Maintenance window."
  default = {
    day_of_week  = 6
    start_hour   = 0
    start_minute = 0
  }
}

variable "ha_enabled" {
  type        = bool
  description = "Indicates if HA is enabled."
  default     = null
}

locals {
  ha_enabled               = var.ha_enabled != null ? var.ha_enabled : (data.azurerm_resource_group.rg.tags.environment != "qas" && data.azurerm_resource_group.rg.tags.environment != "dev")
  environment              = data.azurerm_resource_group.rg.tags.environment
  users_ip_range_whitelist = concat(var.ip_range_whitelist, local.default_ip_ranges_list, [local.executor_public_ip])
  executor_public_ip       = "${trimspace(data.http.my_public_ip.response_body)}/32"
  default_ip_ranges_list   = []
}
