resource "azurerm_eventhub_namespace" "ns" {
  name                = "evhns-${var.identifier}"
  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.rg.location
  tags                = data.azurerm_resource_group.rg.tags
  sku                 = var.sku

  identity {
    type = "SystemAssigned"
  }

  capacity                 = var.capacity
  auto_inflate_enabled     = var.auto_inflate_enabled
  maximum_throughput_units = var.maximum_throughput_units


  network_rulesets {
    default_action                 = "Deny"
    trusted_service_access_enabled = true
    virtual_network_rule = [for subnet in var.subnets_id_whitelist : {
      ignore_missing_virtual_network_service_endpoint = false
      subnet_id                                       = subnet
    }]
    ip_rule = [for ip in local.users_ip_range_whitelist : {
      ip_mask = ip
      action  = "Allow"
    }]
  }
}



resource "azurerm_eventhub" "eh" {
  for_each          = var.event_hubs
  name              = each.key
  namespace_id      = azurerm_eventhub_namespace.ns.id
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention_days
  status            = each.value.status
  dynamic "capture_description" {
    for_each = each.value.capture.enabled && local.enable_capture ? [1] : []
    content {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = each.value.capture.interval_in_seconds
      size_limit_in_bytes = each.value.capture.size_limit_in_bytes
      skip_empty_archives = each.value.capture.skip_empty_archives
      destination {
        name                = "EventHubArchive.AzureBlockBlob"
        archive_name_format = each.value.capture.archive_name_format
        blob_container_name = local.blob_container_name
        storage_account_id  = local.storage_account_id
      }
    }
  }
}

resource "azurerm_eventhub_authorization_rule" "eha" {
  depends_on = [azurerm_eventhub.eh]
  for_each   = { for rule in local.flattened_authorization_rules : rule.id => rule }

  name                = each.value.rule_name
  namespace_name      = azurerm_eventhub_namespace.ns.name
  eventhub_name       = each.value.event_hub_name
  resource_group_name = data.azurerm_resource_group.rg.name

  listen = each.value.listen
  send   = each.value.send
  manage = each.value.manage
}

resource "azurerm_eventhub_consumer_group" "ehcg" {
  for_each            = { for cgroup in local.event_hub_consummer_groups : "${cgroup.event_hub_name}-${cgroup.consumer_group}" => cgroup }
  name                = each.value.consumer_group
  namespace_name      = azurerm_eventhub_namespace.ns.name
  eventhub_name       = each.value.event_hub_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
