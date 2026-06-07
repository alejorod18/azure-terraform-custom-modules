resource "null_resource" "saj" {
  triggers = {
    resource_group_name                      = data.azurerm_resource_group.rg.name
    sku_name                                 = var.sku_name
    compatibility_level                      = var.compatibility_level
    data_locale                              = var.data_locale
    events_out_of_order_policy               = var.events_out_of_order_policy
    events_out_of_order_max_delay_in_seconds = tostring(var.events_out_of_order_max_delay_in_seconds)
    events_late_arrival_max_delay_in_seconds = tostring(var.events_late_arrival_max_delay_in_seconds)
    output_error_policy                      = var.output_error_policy
    streaming_units                          = tostring(var.streaming_units)
    enable_private_access                    = tostring(var.enable_private_access)
  }
}


resource "azurerm_stream_analytics_job" "saj" {
  name                                     = "saj-${var.identifier}"
  location                                 = data.azurerm_resource_group.rg.location
  resource_group_name                      = data.azurerm_resource_group.rg.name
  tags                                     = data.azurerm_resource_group.rg.tags
  sku_name                                 = var.sku_name
  compatibility_level                      = var.compatibility_level
  data_locale                              = var.data_locale
  events_out_of_order_policy               = var.events_out_of_order_policy
  events_out_of_order_max_delay_in_seconds = var.events_out_of_order_max_delay_in_seconds
  events_late_arrival_max_delay_in_seconds = var.events_late_arrival_max_delay_in_seconds
  output_error_policy                      = var.output_error_policy
  streaming_units                          = var.streaming_units
  transformation_query                     = var.transformation_query
  dynamic "job_storage_account" {
    for_each = var.enable_private_access ? [1] : []
    content {
      account_name = azurerm_storage_account.storage[0].name
      account_key  = azurerm_storage_account.storage[0].primary_access_key
    }
  }
  identity {
    type = "SystemAssigned"
  }
  lifecycle {
    ignore_changes = [transformation_query, location, tags, job_storage_account]
    replace_triggered_by = [
      null_resource.saj.triggers
    ]
  }
}

resource "azurerm_stream_analytics_stream_input_eventhub" "input_eventhub" {
  for_each                  = var.eventhubs_inputs
  name                      = each.key
  resource_group_name       = data.azurerm_resource_group.rg.name
  stream_analytics_job_name = azurerm_stream_analytics_job.saj.name
  servicebus_namespace      = each.value.servicebus_namespace
  eventhub_name             = each.value.eventhub_name
  authentication_mode       = "ConnectionString"
  shared_access_policy_key  = each.value.shared_access_policy_key
  shared_access_policy_name = each.value.shared_access_policy_name
  partition_key             = each.value.partition_key
  serialization {
    type            = each.value.serialization.type
    encoding        = each.value.serialization.encoding
    field_delimiter = each.value.serialization.field_delimiter == "" ? null : each.value.serialization.field_delimiter
  }
  depends_on = [null_resource.update_stream_analytics_subnet_config]
  lifecycle {
    replace_triggered_by = [
      null_resource.saj.triggers
    ]
  }
}

resource "azurerm_stream_analytics_output_eventhub" "output_eventhub" {
  for_each                  = var.eventhubs_outputs
  name                      = each.key
  resource_group_name       = data.azurerm_resource_group.rg.name
  stream_analytics_job_name = azurerm_stream_analytics_job.saj.name
  servicebus_namespace      = each.value.servicebus_namespace
  eventhub_name             = each.value.eventhub_name
  authentication_mode       = "ConnectionString"
  shared_access_policy_key  = each.value.shared_access_policy_key
  shared_access_policy_name = each.value.shared_access_policy_name
  partition_key             = each.value.partition_key
  serialization {
    type            = each.value.serialization.type
    encoding        = each.value.serialization.encoding
    format          = each.value.serialization.type == "Json" ? each.value.serialization.format : null
    field_delimiter = each.value.serialization.field_delimiter == "" ? null : each.value.serialization.field_delimiter
  }
  lifecycle {
    replace_triggered_by = [
      null_resource.saj.triggers
    ]
  }
  depends_on = [null_resource.update_stream_analytics_subnet_config]
}