variable "resource_group_name" {
  description = "The resource group to which the existing or to-be-created Key Vault belongs."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "identifier" {
  description = "The name of the existing or to-be-created Event Hub."
  type        = string
  validation {
    condition     = length(lower(replace(var.identifier, "-", ""))) >= 3 && length(lower(replace(var.identifier, "-", ""))) <= 50
    error_message = "The identifier must be between 3 and 50 characters long, excluding hyphens ('-')."
  }
}

variable "sku" {
  description = "The SKU tier of the EventHub namespace."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "free"], var.sku)
    error_message = "The SKU must be either 'standard' or 'free'."
  }
}

variable "log_analytics_workspace_id" {
  description = "The name of the existing Log Analytics Workspace to be used for diagnostic settings and logging in Azure resources."
  type        = string
  default     = ""
  validation {
    condition     = var.log_analytics_workspace_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "The log_analytics_workspace_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
  }
}


variable "keyvault_managed_identity_name" {
  description = "The ID of the managed identity to use for the App Service."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.keyvault_managed_identity_name))
    error_message = "The managed_identity_name can only contain alphanumeric characters, underscores, and dashes."
  }
  default = ""
}

variable "reader_managed_identity_name" {
  description = "The ID of the managed identity to use for the App Service."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.reader_managed_identity_name))
    error_message = "The managed_identity_name can only contain alphanumeric characters, underscores, and dashes."
  }
  default = ""
}

variable "purge_protection_enabled" {
  description = "Habilita o deshabilita la protección contra purgas en el App Configuration."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Número de días para retención de eliminación suave."
  type        = number
  default     = 7
}

variable "local_auth_enabled" {
  description = "Habilita o deshabilita la autenticación local para App Configuration."
  type        = bool
  default     = true
}

variable "enable_public_access" {
  description = "Controla el acceso de red pública al App Configuration. Opciones: 'Enabled' o 'Disabled'."
  type        = bool
  default     = true
}

variable "replica_enabled" {
  description = "Controla si se debe crear una réplica en 'West US' para entornos de producción."
  type        = bool
  default     = false
}

variable "secrets" {
  description = "A map of secret."
  type        = map(string)
  sensitive   = true
}

variable "variables" {
  description = "A map of variable."
  type        = map(string)
  default     = {}
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

locals {
  processed_secrets = { for key, value in var.secrets :
    key => length(split("/", value)) <= 5 ? value : join("/", slice(split("/", value), 0, length(split("/", value)) - 1))
  }
  replica_enabled       = var.replica_enabled ? var.replica_enabled : data.azurerm_resource_group.rg.tags["environment"] == "prd"
  public_network_access = var.enable_public_access ? "Enabled" : "Disabled"
}