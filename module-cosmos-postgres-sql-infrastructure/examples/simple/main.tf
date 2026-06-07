module "cosmos_pg" {
  source                        = "../../"
  resource_group_name           = "test-git"
  identifier                    = "test"
  ip_range_whitelist            = ["192.168.1.0/24", "10.0.0.0/16"]
  shards_on_coordinator_enabled = true
  log_analytics_workspace_id    = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-common-adm-dev/providers/Microsoft.OperationalInsights/workspaces/log-common-adm-dev"
  users_names_list              = ["test"]
}