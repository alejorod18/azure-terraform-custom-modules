
variable "identifier" {
  description = "El nombre del keyvault existente o a ser creado."
  type        = string
  validation {
    condition     = length(var.identifier) >= 3 && length(var.identifier) <= 70
    error_message = "The identifier must be between 3 and 70 characters long."
  }
}

variable "resource_group_name" {
  description = "El resource group al que pertenece el keyvault existente o a ser creado."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "virtual_network_name" {
  description = "Name of the virtual network where the subnet will be created."
  type        = string

  validation {
    condition     = length(var.virtual_network_name) > 0
    error_message = "The virtual network name must not be empty."
  }
}

variable "subnet_address_prefix" {
  description = "Address prefixes for the subnet."
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]+$", var.subnet_address_prefix))
    error_message = "The subnet address prefix must be in CIDR format (e.g., 10.0.0.0/24)."
  }
}
variable "enable_service_endpoints" {
  description = "Enable service endpoints for the subnet."
  type        = bool
  default     = false
}

variable "enable_app_service_delegation" {
  description = "Enable delegation for App Service."
  type        = bool
  default     = false
}

variable "enable_containers_delegation" {
  description = "Enable delegation for Containers."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for the subnet."
  type        = bool
  default     = false
}

variable "enable_stream_analytics_job_delegation" {
  description = "Enable delegation for Stream Analytics Jobs."
  type        = bool
  default     = false
}

variable "enable_private_endpoint_network_policies" {
  description = "Enable private endpoint network policies for the subnet."
  type        = bool
  default     = false
}

locals {
  environment = data.azurerm_resource_group.rg.tags.environment
  location    = data.azurerm_resource_group.rg.location
  tags        = data.azurerm_resource_group.rg.tags
}
