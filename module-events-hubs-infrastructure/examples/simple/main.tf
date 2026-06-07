# example.tf
module "eventhub_module" {
  source = "../../"

  identifier                     = "custom-eventhubs-test"
  resource_group_name            = "test-git"
  create_capture_storage_account = true
  subnets_id_whitelist           = [azurerm_subnet.subnet.id]
  schema_groups = {
    "schema-group-1" = {
      compatibility = "Backward"
      type          = "Avro"
    }
  }
  event_hubs = {
    "example-hub-1" = {
      partition_count        = 2
      message_retention_days = 7
      capture = {
        enabled             = true
        interval_in_seconds = 300
        size_limit_in_bytes = 10485760
      }
      consumer_groups = ["example-consumer-group-1", "example-consumer-group-2"]
      authorization_rules = {
        listen = {
          listen = true
          send   = false
          manage = false
        },
        send = {
          listen = false
          send   = true
          manage = false
        }
      }
    }
    "example-hub-2" = {
      partition_count        = 1
      message_retention_days = 3
      capture = {
        enabled = false
      }
      authorization_rules = {
        listen = {
          listen = true
          send   = false
          manage = false
        },
        send = {
          listen = false
          send   = true
          manage = false
        }
      }
    }
  }
}