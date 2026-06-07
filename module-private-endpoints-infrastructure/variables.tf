variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the resource will be created."
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "subnet_id" {
  description = "ID of the subnet where the Private Endpoint will be created."
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.subnet_id))
    error_message = "The subnet_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

variable "resource_id" {
  description = "ID of the resource to which the Private Endpoint will connect."
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.resource_id))
    error_message = "The resource_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

variable "identifier" {
  description = "Unique identifier for the resource."
  type        = string
  validation {
    condition     = length(var.identifier) >= 3 && length(var.identifier) <= 70
    error_message = "The identifier must be between 3 and 70 characters long."
  }
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone."
  type        = string
  default     = ""
  validation {
    condition     = var.private_dns_zone_name == "" || can(regex("^privatelink\\.[a-z0-9-]+(\\.[a-z0-9-]+)*\\.(com|net|io)$", var.private_dns_zone_name))
    error_message = <<EOT
The private DNS zone name must follow the format:
privatelink.<service>.azure.<domain>
Where:
  - <service>: Name of the Azure service (e.g., blob, sql, etc.).
  - <domain>: Must be 'com' or 'net'.

Valid examples:
  - privatelink.blob.azure.com
  - privatelink.sql.azure.net

You can find more information in the official Azure documentation:
https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
EOT
  }
}

variable "subresource_name" {
  description = "Name of the subresource to which the Private Endpoint will connect."
  type        = string
  default     = ""
}

variable "existing_private_dns_zone_id" {
  description = "ID of the existing private DNS zone."
  type        = string
  default     = ""
  validation {
    condition     = var.existing_private_dns_zone_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.existing_private_dns_zone_id))
    error_message = "The existing_private_dns_zone_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

locals {
  vnet_id        = join("/", slice(split("/", var.subnet_id), 0, 9))
  private_dns_id = var.existing_private_dns_zone_id != "" ? var.existing_private_dns_zone_id : (var.existing_private_dns_zone_id == "" && var.private_dns_zone_name != "") ? azurerm_private_dns_zone.dns[0].id : ""
}