variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the Storage Account will be deployed."
}

variable "identifier" {
  type        = string
  description = "Unique identifier for the resource."
  validation {
    condition = (
      length(var.identifier) >= 3 &&
      length(var.identifier) <= 20 &&
      can(regex("^[a-z0-9]*$", var.identifier))
    )
    error_message = "The identifier must be between 3 and 20 characters long, contain only lowercase letters and numbers, and must not include special characters."
  }
}

variable "account_kind" {
  type        = string
  description = "The type of Storage Account. Valid options are 'BlobStorage', 'BlockBlobStorage', 'FileStorage', 'Storage', and 'StorageV2'. Defaults to 'StorageV2'."
  default     = "StorageV2"
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "The account_kind must be one of the following: 'BlobStorage', 'BlockBlobStorage', 'FileStorage', 'Storage', or 'StorageV2'."
  }
}

variable "account_tier" {
  type        = string
  description = "The tier of the Storage Account. Valid options are 'Standard' or 'Premium'. Defaults to 'Standard'."
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "The account_tier must be either 'Standard' or 'Premium'. For BlockBlobStorage and FileStorage accounts, only 'Premium' is valid."
  }
}

variable "account_replication_type" {
  type        = string
  description = "The replication type of the Storage Account. Valid options are 'LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', and 'RAGZRS'. Defaults to 'LRS'."
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "The account_replication_type must be one of the following: 'LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', or 'RAGZRS'. Changing this may force a new resource to be created when switching between LRS/GRS/RAGRS and ZRS/GZRS/RAGZRS."
  }
}

variable "enable_https_traffic_only" {
  type        = bool
  description = "Indicates whether only HTTPS traffic is allowed on the Storage Account."
  default     = true
}

variable "is_hns_enabled" {
  type        = bool
  description = "Indicates whether the hierarchical namespace system (HNS) is enabled. This is required for Data Lake Gen2."
  default     = true
}

variable "min_tls_version" {
  type        = string
  description = "The minimum supported TLS version for the storage account. Valid options are 'TLS1_0', 'TLS1_1', and 'TLS1_2'. Defaults to 'TLS1_2'."
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "The min_tls_version must be one of the following: 'TLS1_0', 'TLS1_1', or 'TLS1_2'."
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
    error_message = "All elements in ip_range_whitelist must be valid IP addresses or ranges in CIDR notation."
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

variable "large_file_share_enabled" {
  type        = bool
  description = "Indicates whether the storage account supports large file shares with more than 5 TiB capacity."
  default     = false
}

variable "enable_public_access" {
  type        = bool
  description = "Specifies whether data in the container may be accessed publicly and the level of access. Possible values are 'Container', 'Blob', or 'None'."
  default     = false
}

variable "containers" {
  type = map(object({
    enable_public_access = optional(bool, false)
  }))
  description = "Map of containers to create in the storage account."
  default     = {}
}

locals {
  account_replication_type = data.azurerm_resource_group.rg.tags.environment == "prd" ? "GRS" : var.account_replication_type
  users_ip_range_whitelist = concat(var.ip_range_whitelist, local.default_ip_ranges_list, [local.executor_public_ip])
  executor_public_ip       = trimspace(data.http.my_public_ip.response_body)
  default_ip_ranges_list   = []
}