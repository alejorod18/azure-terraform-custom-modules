variable "environment_secrets" {
  type    = map(string)
  default = {}
}

variable "github_repository" {
  description = "Source repository from which secrets will be taken to be created in Key Vault."
  type        = string
  default     = ""
}

variable "identifier" {
  description = "The name of the existing or to-be-created Key Vault."
  type        = string
  validation {
    condition     = length(var.identifier) >= 3 && length(var.identifier) <= 20
    error_message = "The identifier must be between 3 and 18 characters long."
  }
}

variable "resource_group_name" {
  description = "The resource group to which the existing or to-be-created Key Vault belongs."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "subnets_id_whitelist" {
  description = "Azure subnets allowed access to the Key Vault."
  type        = list(string)
  default     = []
  validation {
    condition     = var.subnets_id_whitelist == [] || alltrue([for id in var.subnets_id_whitelist : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", id))])
    error_message = "Each subnet ID must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

variable "ip_range_whitelist" {
  description = "CIDRs allowed access to the Key Vault."
  type        = list(string)
  default     = []
  validation {
    condition = var.ip_range_whitelist == [] || alltrue([
      for ip in var.ip_range_whitelist : can(regex(
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/(3[0-2]|[12]?[0-9])$",
        ip
      ))
    ])
    error_message = "All elements in ip_range_whitelist must be valid IP addresses or ranges in CIDR notation."
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

variable "access_policies" {
  description = "List of access policies for the Key Vault. Each policy contains a principal_id and the actions allowed."
  type = list(object({
    principal_id = string
    actions      = list(string)
  }))
}

variable "github_secrets_regex_filter" {
  type    = string
  default = "^ARM_.*"
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

variable "enable_public_access" {
  type    = bool
  default = false
}

locals {
  network_acls_default_action = var.enable_public_access ? "Allow" : "Deny"
  github_environment_secrets  = merge([for s in data.external.get_secret : tomap(s.result)]...)
  executor_permissions = {
    principal_id = data.azurerm_client_config.azure_provider_config.object_id
    actions = [
      "get",
      "list",
      "set",
      "delete",
      "recover"
    ]
  }
  all_access_policies      = concat(var.access_policies, [local.executor_permissions])
  tags                     = data.azurerm_resource_group.rg.tags
  users_ip_range_whitelist = concat(var.ip_range_whitelist, local.default_ip_ranges_list, [local.executor_public_ip])
  executor_public_ip       = "${trimspace(data.http.my_public_ip.response_body)}/32"
  default_ip_ranges_list   = []
  github_repository_name   = var.github_repository != "" ? var.github_repository : lookup(data.external.get_github_repository_name.result, "repository_name", "")
}