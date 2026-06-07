module "stream_analytics" {
  source                = "../../"
  identifier            = "mo-ule-test-asdasd-asdasdaqas"
  resource_group_name   = "test-git"
  subnet_id             = "/subscriptions/<your-azure-subscription-id>/resourceGroups/rg-networking-qas/providers/Microsoft.Network/virtualNetworks/vnet-data-qas-eastus-003/subnets/subnet-001"
  enable_private_access = true
  transformation_query  = <<QUERY
SELECT
    source.*, source.data.partnerId as customer_id
INTO
    [evh-accountset-ordered]
FROM
    [evh-accountset] as source
TIMESTAMP BY
	source.time
    QUERY
  eventhubs_inputs = {
    "input-1" = {
      servicebus_namespace     = "eh-custom-eventhubs-test"
      eventhub_name            = "eha-example-hub-1"
      shared_access_policy_key = "{CONNECTION_STRING}"
    }
  }
  eventhubs_outputs = {
    "output-1" = {
      servicebus_namespace     = "eh-custom-eventhubs-test"
      eventhub_name            = "eha-example-hub-2"
      shared_access_policy_key = "{CONNECTION_STRING}"
    }
  }
}