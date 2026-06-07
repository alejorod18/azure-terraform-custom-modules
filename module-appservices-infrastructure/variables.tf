variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "identifier" {
  description = "Unique identifier for the resource."
  type        = string
  validation {
    condition     = length(var.identifier) >= 3 && length(var.identifier) <= 55
    error_message = "The identifier must be between 3 and 55 characters long."
  }
}

variable "sku_name" {
  description = "The SKU name for the Azure App Service Plan. Valid values: F1, D1, B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3."
  type        = string

  #   validation {
  #     condition = contains([
  #       "F1",
  #       "D1", # Free and Shared SKUs
  #       "B1",
  #       "B2",
  #       "B3", # Basic SKUs
  #       "S1",
  #       "S2",
  #       "S3", # Standard SKUs
  #       "P0v1",
  #       "P0v2",
  #       "P1v2",
  #       "P2v2",
  #       "P3v2", # Premium V2 SKUs
  #       "P1v3",
  #       "P2v3",
  #       "P3v3" # Premium V3 SKUs
  #     ], var.sku_name)
  #     error_message = "Invalid service plan SKU. Allowed values are: F1, D1, B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3."
  #   }
}

variable "managed_identity_name" {
  description = "The ID of the managed identity to use for the App Service."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.managed_identity_name))
    error_message = "The managed_identity_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "subnet_id" {
  description = "The ID of the subnet to use for the App Service."
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.subnet_id))
    error_message = "The subnet_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/"
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

variable "scm_ip_range_whitelist" {
  type        = list(string)
  description = "List of IP addresses that will have access to the resource."
  default     = []
  validation {
    condition = var.scm_ip_range_whitelist == [] || alltrue([
      for ip in var.scm_ip_range_whitelist : can(regex(
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/(3[0-2]|[12]?[0-9])$",
        ip
      ))
    ])
    error_message = "Todos los elementos en ip_range_whitelist deben ser direcciones IP válidas o rangos en notación CIDR."
  }
}

variable "scm_subnets_id_whitelist" {
  type        = list(string)
  description = "List of subnet IDs that will have access to the resource."
  default     = []
  validation {
    condition     = var.scm_subnets_id_whitelist == [] || alltrue([for id in var.scm_subnets_id_whitelist : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", id))])
    error_message = "Each subnet ID must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

variable "key_vault_secrets" {
  description = "A map of key vault secrets to apply to the App Service."
  type        = map(string)
  default     = {}
}

variable "backup_storage_account_url" {
  description = "The URL of the storage account to use for backups."
  type        = string
  default     = ""
}


variable "app_service_web_apps" {
  description = "A map of web apps to create within the App Service."
  type = map(object({
    app_settings             = optional(map(string))
    secrets_filter_regex     = optional(string)
    ip_range_whitelist       = optional(list(string), [])
    subnets_id_whitelist     = optional(list(string), [])
    scm_ip_range_whitelist   = optional(list(string), [])
    scm_subnets_id_whitelist = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = length([for key in keys(var.app_service_web_apps) : key if length(key) > 55 || !can(regex("^[a-zA-Z0-9-_]+$", key))]) == 0
    error_message = "All keys in the 'app_service_web_apps' map must be 55 characters or fewer."
  }
}

variable "zone_balancing_enabled" {
  description = "Whether to enable zone balancing for the App Service."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace to use for diagnostics."
  type        = string
  default     = ""
  validation {
    condition     = var.log_analytics_workspace_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "The log_analytics_workspace_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
  }
}

variable "enable_slot" {
  description = "Whether to enable deployment slots for the App Service."
  type        = bool
  default     = false
}

variable "app_service_function_apps" {
  description = "A map of function apps to create within the App Service."
  type = map(object({
    app_settings             = optional(map(string))
    secrets_filter_regex     = optional(string)
    application_type         = string
    application_stack        = map(string)
    ip_range_whitelist       = optional(list(string), [])
    subnets_id_whitelist     = optional(list(string), [])
    scm_ip_range_whitelist   = optional(list(string), [])
    scm_subnets_id_whitelist = optional(list(string), [])
  }))
  default = {}
  validation {
    condition     = length([for key in keys(var.app_service_function_apps) : key if length(key) > 50 || !can(regex("^[a-zA-Z0-9-_]+$", key))]) == 0
    error_message = "All keys in the 'app_service_function_apps' map must be 50 characters or fewer."
  }
}

locals {
  its_non_production = local.environment != "dev" && local.environment != "qas"

  environment             = lower(data.azurerm_resource_group.rg.tags.environment)
  zone_balancing_enabled  = var.zone_balancing_enabled || local.environment == "prd" || local.environment == "drp"
  needs_slots             = local.its_non_production || var.enable_slot
  app_function_allways_on = local.its_non_production
  web_apps_properties = {
    for name, properties in var.app_service_web_apps : lower(replace(name, "_", "-")) =>
    {
      app_settings = merge(
        lookup(properties, "app_settings", {}), {
          for key, value in var.key_vault_secrets : key => "@Microsoft.KeyVault(SecretUri=${value})"
          if can(regex(coalesce(lookup(properties, "secrets_filter_regex", ".*"), ".*"), key))
        },
        {
          WEBSITE_PULL_IMAGE_OVER_VNET = "1"
        }
      )
      ip_range_whitelist       = properties.ip_range_whitelist
      subnets_id_whitelist     = properties.subnets_id_whitelist
      scm_ip_range_whitelist   = properties.scm_ip_range_whitelist
      scm_subnets_id_whitelist = properties.scm_subnets_id_whitelist
    }
  }
  function_apps_properties = {
    for name, properties in var.app_service_function_apps : name =>
    {
      app_settings = merge(
        lookup(properties, "app_settings", {}), {
          for key, value in var.key_vault_secrets : key => "@Microsoft.KeyVault(SecretUri=${value})"
          if can(regex(coalesce(lookup(properties, "secrets_filter_regex", ".*"), ".*"), key))
        },
        {
          WEBSITE_PULL_IMAGE_OVER_VNET = "1"
        }
      )
      application_type         = properties.application_type
      application_stack        = properties.application_stack
      ip_range_whitelist       = properties.ip_range_whitelist
      subnets_id_whitelist     = properties.subnets_id_whitelist
      scm_ip_range_whitelist   = properties.scm_ip_range_whitelist
      scm_subnets_id_whitelist = properties.scm_subnets_id_whitelist
    }
  }
  users_ip_range_whitelist = concat(var.ip_range_whitelist, local.default_ip_ranges_list, [local.executor_public_ip])
  executor_public_ip       = "${trimspace(data.http.my_public_ip.response_body)}/32"
  default_ip_ranges_list   = []
}
