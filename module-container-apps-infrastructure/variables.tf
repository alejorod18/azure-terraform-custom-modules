
variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
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

variable "identifier" {
  description = "Unique identifier for the resource."
  type        = string
  validation {
    condition     = length(var.identifier) >= 3 && length(var.identifier) <= 20
    error_message = "The identifier must be between 3 and 18 characters long."
  }
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for diagnostics."
  type        = string
  validation {
    condition     = var.log_analytics_workspace_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "The log_analytics_workspace_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
  }
}

variable "managed_identity_name" {
  description = "The ID of the managed identity to use for the App Service."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.managed_identity_name))
    error_message = "The managed_identity_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "zone_redundancy_enabled" {
  description = "Whether to enable zone redundancy for the App Service."
  type        = bool
  default     = false
}

variable "key_vault_secrets" {
  description = "A map of key vault secrets to apply to the App Service."
  type        = map(string)
  default     = {}
}

variable "container_registry_login_server" {
  description = "The server URL of the container registry."
  type        = string
}

variable "container_apps" {
  description = "A map of container apps to create within the App Service."
  type = map(object({
    environment_variables = optional(map(string))
    secrets_filter_regex  = optional(string)
    min_replicas          = optional(number)
    max_replicas          = optional(number)
    cpu                   = number
    memory                = string
    port                  = number
  }))
  default = {}

  validation {
    condition     = length([for key in keys(var.container_apps) : key if length(key) > 28 || !can(regex("^[a-zA-Z0-9-_]+$", key))]) == 0
    error_message = "All keys in the 'container_apps' map must be 28 characters or fewer."
  }
}

variable "internal_load_balancer_enabled" {
  description = "Whether to enable an internal load balancer for the App Service."
  type        = bool
  default     = true
}

locals {
  executor_public_ip      = trimspace(data.http.my_public_ip.response_body)
  environment             = lower(data.azurerm_resource_group.rg.tags.environment)
  its_production          = local.environment == "prd" || local.environment == "drp"
  zone_redundancy_enabled = local.its_production
  container_apps_properties = {
    for name, properties in var.container_apps : lower(replace(name, "_", "-")) =>
    {
      environment_variables = lookup(properties, "environment_variables", {})
      secrets = {
        for key, value in var.key_vault_secrets : key => value
        if can(regex(coalesce(lookup(properties, "secrets_filter_regex", ".*"), ".*"), key))
      }
      min_replicas = lookup(properties, "min_replicas", 0)
      max_replicas = local.its_production ? lookup(properties, "max_replicas", 10) : lookup(properties, "max_replicas", 1)
      cpu          = properties.cpu
      memory       = properties.memory
      port         = properties.port
    }
  }
}