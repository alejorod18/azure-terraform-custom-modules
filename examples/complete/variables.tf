# =============================================================================
# General
# =============================================================================

variable "subscription_id" {
  description = "The Azure Subscription ID where resources will be created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the existing Azure Virtual Network."
  type        = string
}

variable "identifier" {
  description = "A unique identifier used to name all resources (e.g., project name or environment slug)."
  type        = string
  default     = "example"
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings."
  type        = string
}

# =============================================================================
# Networking
# =============================================================================

variable "subnet_appservice_prefix" {
  description = "Address prefix for the App Service subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_private_endpoints_prefix" {
  description = "Address prefix for the Private Endpoints subnet."
  type        = string
  default     = "10.0.2.0/24"
}

# =============================================================================
# App Service
# =============================================================================

variable "app_service_sku" {
  description = "SKU for the App Service Plan (e.g., P1v2, P2v2, S1)."
  type        = string
  default     = "P1v2"
}

# =============================================================================
# Cosmos DB
# =============================================================================

variable "cosmos_databases" {
  description = "Map of Cosmos DB SQL databases and their containers to create."
  type = map(map(object({
    partition_key_paths = list(string)
    excluded_paths      = optional(list(string))
    max_throughput      = optional(number)
  })))
  default = {
    "appdb" = {
      "users" = {
        partition_key_paths = ["/userId"]
        max_throughput      = 1000
      }
      "events" = {
        partition_key_paths = ["/eventType"]
        max_throughput      = 1000
      }
    }
  }
}

# =============================================================================
# Event Hubs
# =============================================================================

variable "event_hubs" {
  description = "Map of Event Hubs to create within the namespace."
  type = map(object({
    partition_count   = number
    message_retention = number
    consumer_groups   = list(string)
  }))
  default = {
    "telemetry" = {
      partition_count   = 4
      message_retention = 7
      consumer_groups   = ["analytics", "processor"]
    }
  }
}

# =============================================================================
# Storage
# =============================================================================

variable "storage_containers" {
  description = "List of blob container names to create in the storage account."
  type        = list(string)
  default     = ["data", "backups", "uploads"]
}
