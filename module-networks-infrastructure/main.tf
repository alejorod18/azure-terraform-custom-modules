resource "azurerm_subnet" "net" {
  name                              = "snet-${var.identifier}"
  resource_group_name               = data.azurerm_resource_group.rg.name
  virtual_network_name              = var.virtual_network_name
  address_prefixes                  = [var.subnet_address_prefix]
  private_endpoint_network_policies = var.enable_private_endpoint_network_policies ? "Enabled" : "Disabled"
  service_endpoints = var.enable_service_endpoints ? [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.AzureActiveDirectory",
    "Microsoft.AzureCosmosDB",
    "Microsoft.Web",
    "Microsoft.KeyVault",
    "Microsoft.EventHub",
    "Microsoft.ServiceBus",
    "Microsoft.ContainerRegistry",
    "Microsoft.CognitiveServices",
  ] : []

  dynamic "delegation" {
    for_each = var.enable_containers_delegation ? [1] : []
    content {
      name = "container-app-environment"
      service_delegation {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
  dynamic "delegation" {
    for_each = var.enable_app_service_delegation ? [1] : []
    content {
      name = "web-apps"
      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
  dynamic "delegation" {
    for_each = var.enable_stream_analytics_job_delegation ? [1] : []
    content {
      name = "stream-analytics"
      service_delegation {
        name    = "Microsoft.StreamAnalytics/streamingJobs"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}