data "azurerm_resource_group" "rg" {
  name = "test-git"
}

resource "azurerm_user_assigned_identity" "app_service" {
  name                = "mi-kv-example"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = data.azurerm_resource_group.rg.tags
}

module "sync_github_to_keyvault" {
  source                      = "../../"
  github_secrets_regex_filter = "TEST"
  identifier                  = "testingSecurity"
  resource_group_name         = "test-git"
  github_repository           = "module-secrets-infrastructure"
  environment_secrets = {
    "GH_PAT" : var.github_token,
    "GH_REPO" : "module-secrets-infrastructure",
    "Loancontract:CosmosDB:Key" : "cosmosdb-key",
  }
  access_policies = [
    {
      principal_id = azurerm_user_assigned_identity.app_service.principal_id
      actions      = ["get", "list"]
    }
  ]
  log_analytics_workspace_id = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-common-adm-dev/providers/Microsoft.OperationalInsights/workspaces/log-common-adm-dev"
  private_endpoints = [{
    "subnet_id" : "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-adm-dev-eastus-008/subnets/snet-pe-sap-adm-dev"
    # Optional existing_private_dns_zone_id
    "existing_private_dns_zone_id" = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-sap-adm-dev/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  }]
}


