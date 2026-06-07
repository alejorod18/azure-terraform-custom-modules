variable "identifier" {
  description = "The name of the existing or to-be-created Event Hub."
  type        = string
  validation {
    condition     = length(lower(replace(var.identifier, "-", ""))) >= 3 && length(lower(replace(var.identifier, "-", ""))) <= 60
    error_message = "The identifier must be between 3 and 60 characters long, excluding hyphens ('-')."
  }
}

variable "resource_group_name" {
  description = "The resource group to which the existing or to-be-created Event Hub belongs."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name can only contain alphanumeric characters, underscores, and dashes."
  }
}

variable "compatibility_level" {
  description = "Compatibility level for the Stream Analytics Job."
  type        = string
  default     = "1.2"
}

variable "data_locale" {
  description = "Data locale for the Stream Analytics Job."
  type        = string
  default     = "en-US"
}

variable "events_out_of_order_policy" {
  description = "Policy for handling events out of order."
  type        = string
  default     = "Adjust"
}

variable "events_out_of_order_max_delay_in_seconds" {
  description = "Maximum delay in seconds for events out of order."
  type        = number
  default     = 5
}

variable "events_late_arrival_max_delay_in_seconds" {
  description = "Maximum delay in seconds for late arrival events."
  type        = number
  default     = 5
}

variable "output_error_policy" {
  description = "Policy for handling output errors."
  type        = string
  default     = "Stop"
}

variable "streaming_units" {
  description = "Number of streaming units for the Stream Analytics Job."
  type        = number
  default     = 3
}

variable "sku_name" {
  description = "SKU name for the Stream Analytics Job."
  type        = string
  default     = "StandardV2"
}

variable "transformation_query" {
  description = "Query for the transformation in the Stream Analytics Job."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to use for the Stream Analytics Job."
  type        = string
  default     = ""
  validation {
    condition     = var.subnet_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.subnet_id))
    error_message = "The subnet_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/"
  }
}

variable "enable_private_access" {
  description = "Enable the subnet for the Stream Analytics Job."
  type        = bool
  default     = false
}

variable "eventhubs_inputs" {
  description = "The Stream Analytics eventhub inputs."
  type = map(object(
    {
      servicebus_namespace      = string
      eventhub_name             = string
      shared_access_policy_key  = string
      shared_access_policy_name = optional(string, "RootManageSharedAccessKey")
      partition_key             = optional(string, null)
      serialization = optional(object(
        {
          type            = string
          encoding        = string
          field_delimiter = optional(string, "")
        }),
        {
          type            = "Json"
          encoding        = "UTF8"
          field_delimiter = ""
        }
      )
    })
  )
}

variable "eventhubs_outputs" {
  description = "The Stream Analytics eventhub outputs."
  type = map(object(
    {
      servicebus_namespace      = string
      eventhub_name             = string
      shared_access_policy_key  = string
      shared_access_policy_name = optional(string, "RootManageSharedAccessKey")
      partition_key             = optional(string, null)
      serialization = optional(object(
        {
          type            = optional(string, "Json")
          encoding        = optional(string, "UTF8")
          format          = optional(string, "Array")
          field_delimiter = optional(string, "")
        }
        ),
        {
          type            = "Json"
          encoding        = "UTF8"
          field_delimiter = ""
        }
      )
    })
  )
}

locals {
  cleaned_identifier = replace(replace(lower(var.identifier), "-", ""), "_", "")
  storage_identifier = length(local.cleaned_identifier) <= 24 ? local.cleaned_identifier : "${substr(local.cleaned_identifier, 0, 21)}${substr(local.cleaned_identifier, length(local.cleaned_identifier) - 3, 3)}"
}
