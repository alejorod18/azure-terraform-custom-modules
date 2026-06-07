module "cosmosdb_example" {
  source               = "../../"
  resource_group_name  = "ResourceGroup-1"
  identifier           = "example_cosmosdb"
  ip_range_whitelist   = ["189.203.89.145/32"]
  subnets_id_whitelist = []
  private_endpoints    = [{ "subnet_id" : "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-adm-dev-eastus-008/subnets/snet-pe-sap-adm-dev" }]
  sql_databases = {
    "cdb_internal_consumption" = {
      "account_token_mapping" = {
        partition_key_paths = ["/id"]
      },
    },
    "personal_loan" = {
      "application" = {
        partition_key_paths = ["/p_application_date"]
        max_throughput      = 20000
      },
      "related_persons" = {
        partition_key_paths = ["/p_upload_month"]
      },
    },
    "credit_card" = {
      "application" = {
        partition_key_paths = ["/p_application_date"]
      },
      "available_offers" = {
        partition_key_paths = ["/p_application_date"]
      },
    }
  }
  log_analytics_workspace_id = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-common-adm-dev/providers/Microsoft.OperationalInsights/workspaces/log-common-adm-dev"
}


