variable "identifier" {
  description = "The name of the existing or to-be-created Event Hub."
  type        = string
  validation {
    condition     = length(lower(replace(var.identifier, "-", ""))) >= 3 && length(lower(replace(var.identifier, "-", ""))) <= 50
    error_message = "The identifier must be between 3 and 50 characters long, excluding hyphens ('-')."
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

variable "subnets_id_whitelist" {
  description = "Azure subnets allowed access to the Event Hub."
  type        = list(string)
  default     = []
  validation {
    condition     = var.subnets_id_whitelist == [] || alltrue([for id in var.subnets_id_whitelist : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", id))])
    error_message = "Each subnet ID must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
  }
}

variable "capture_storage_account_name" {
  description = "The name of the storage account  to use for the capture"
  type        = string
  default     = ""
}

variable "capture_storage_account_container_name" {
  description = "The name of the storage account container to use for the capture"
  type        = string
  default     = ""
}

variable "ip_range_whitelist" {
  description = "CIDRs allowed access to the Event Hub."
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

variable "sku" {
  description = "The SKU tier of the EventHub namespace."
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "The capacity or throughput units of the EventHub namespace."
  type        = number
  default     = 1
}

variable "auto_inflate_enabled" {
  description = "Specifies whether auto-inflate is enabled for the EventHub namespace."
  type        = bool
  default     = true
}

variable "maximum_throughput_units" {
  description = "The maximum throughput units for the EventHub namespace."
  type        = number
  default     = 10
}

variable "create_capture_storage_account" {
  description = "Whether to create a storage account for capturing EventHub data."
  type        = bool
  default     = false
}

variable "event_hubs" {
  type = map(object({
    partition_count        = optional(number, 1)
    message_retention_days = optional(number, 1)
    status                 = optional(string, "Active")
    capture = optional(object({
      enabled             = optional(bool, true)
      interval_in_seconds = optional(number, 300)
      size_limit_in_bytes = optional(number, 314572800)
      skip_empty_archives = optional(bool, true)
      archive_name_format = optional(string, "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}")
      }), {
      enabled             = false
      interval_in_seconds = 300
      size_limit_in_bytes = 10485760
      skip_empty_archives = true
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
    })
    consumer_groups = optional(list(string), [])
    authorization_rules = optional(map(object({
      listen = optional(bool, true)
      send   = optional(bool, false)
      manage = optional(bool, false)
      })), {
      default = {
        listen = true
        send   = false
        manage = false
    } })
  }))
  default = {}
}

variable "schema_groups" {
  description = "The schema groups to be created in the Event Hub."
  type = map(object({
    compatibility = string
    type          = optional(string, "AVRO")
  }))
  default = {}
  validation {
    condition = var.schema_groups == {} || alltrue([
      for sg_key, sg_value in var.schema_groups :
      (
        length(sg_key) <= 20 &&
        contains(["None", "Forward", "Backward"], sg_value.compatibility) &&
        contains(["Avro", "Unknown"], sg_value.type)
      )
    ])
    error_message = <<EOT
Cada grupo de esquemas debe cumplir con las siguientes condiciones:
- El nombre generado no debe exceder los 20 caracteres.
- 'compatibility' debe ser uno de: 'None', 'Forward' o 'Backward'.
- 'type' debe ser uno de: 'Avro', 'Unknown'.
    EOT
  }
}

locals {
  enable_existing_storage_account_backup = var.capture_storage_account_name != "" && var.capture_storage_account_container_name != ""
  enable_storage_account_creation        = var.create_capture_storage_account && !local.enable_existing_storage_account_backup
  enable_capture                         = local.enable_existing_storage_account_backup || local.enable_storage_account_creation
  blob_container_name                    = var.create_capture_storage_account ? local.enable_storage_account_creation ? azurerm_storage_container.capture_container[0].name : data.azurerm_storage_container.container[0].name : ""
  storage_account_id                     = var.create_capture_storage_account ? local.enable_storage_account_creation ? azurerm_storage_account.capture_storage[0].id : data.azurerm_storage_account.sa[0].id : ""
  enabled_capture_event_hubs             = { for name, properties in var.event_hubs : name => properties if properties.capture.enabled }

  #   eventhub_connection_strings = {
  #     for key, config in azurerm_eventhub_authorization_rule.eha :
  #     key => config.primary_connection_string
  #   }
  eventhub_connection_strings = {
    for hub, config in var.event_hubs : hub => {
      for rule, rule_config in config.authorization_rules :
      rule => azurerm_eventhub_authorization_rule.eha["${hub}-${rule}"].primary_connection_string
    }
  }
  eventhub_primary_keys = {
    for hub, config in var.event_hubs : hub => {
      for rule, rule_config in config.authorization_rules :
      rule => azurerm_eventhub_authorization_rule.eha["${hub}-${rule}"].primary_key
    }
  }

  flattened_authorization_rules = flatten([
    for event_hub_name, event_hub_config in var.event_hubs : [
      for rule_name, rule_config in event_hub_config.authorization_rules : {
        id             = "${event_hub_name}-${rule_name}"
        event_hub_name = event_hub_name
        rule_name      = rule_name
        listen         = rule_config.listen
        send           = rule_config.send
        manage         = rule_config.manage
      }
    ]
  ])

  event_hub_consummer_groups = flatten([
    for hub, config in var.event_hubs : [
      for group in config.consumer_groups :
      {
        event_hub_name = hub
        consumer_group = group
      }
    ]
  ])
  users_ip_range_whitelist = concat(var.ip_range_whitelist, local.default_ip_ranges_list, [local.executor_public_ip])
  executor_public_ip       = trimspace(data.http.my_public_ip.response_body)
  default_ip_ranges_list   = []
}
