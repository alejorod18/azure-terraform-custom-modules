data "azurerm_resource_group" "rg" {
  name = "test-git"
}

resource "azurerm_user_assigned_identity" "mi" {
  name                = "mi-example"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = data.azurerm_resource_group.rg.tags
}

module "keyvault" {
  source               = "github.com/<your-github-username>/module-secrets-infrastructure?ref=0.1.2"
  identifier           = "configModuleTest"
  resource_group_name  = "test-git"
  enable_public_access = true
  environment_secrets = {
    "SECRETO" : "valor-secreto"
  }
  access_policies = [
    {
      principal_id = azurerm_user_assigned_identity.mi.principal_id
      actions      = ["get", "list"]
    }
  ]
}

module "app_configuration" {
  source                         = "../../"
  identifier                     = "appconf-test"
  reader_managed_identity_name   = azurerm_user_assigned_identity.mi.name
  keyvault_managed_identity_name = azurerm_user_assigned_identity.mi.name
  resource_group_name            = "test-git"
  enable_public_access           = true
  variables = {
    "key1" = "value1"
    "key2" = "value2"
  }
  private_endpoints = [
    { "subnet_id" : "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-adm-dev-eastus-008/subnets/snet-pe-sap-adm-dev" },
    { "subnet_id" : "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-adm-dev-eastus-015/subnets/default" }
  ]
  log_analytics_workspace_id = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-common-adm-dev/providers/Microsoft.OperationalInsights/workspaces/log-common-adm-dev"
  secrets                    = module.keyvault.secrets
}