resource "azurerm_key_vault" "secrets" {
  name                            = "kv-${var.identifier}"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.azure_provider_config.tenant_id
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 30
  purge_protection_enabled        = true

  network_acls {
    default_action = local.network_acls_default_action
    bypass         = "AzureServices"

    ip_rules                   = compact(local.users_ip_range_whitelist)
    virtual_network_subnet_ids = compact(var.subnets_id_whitelist)
  }
  tags = local.tags
}

locals {
  non_null_filtered_secrets = toset([
    for s in local.secrets : s.name
    if !can(regex(var.github_secrets_regex_filter, s.name))
    && length(trimspace(local.github_environment_secrets[s.name])) > 0
  ])
}

resource "null_resource" "github_secrets" {
  for_each = local.non_null_filtered_secrets
  triggers = {
    force_recreate = sensitive(each.value)
  }
}

resource "azurerm_key_vault_secret" "github_secrets" {
  for_each     = local.non_null_filtered_secrets
  name         = lower(replace(replace(replace(each.key, ":", "-"), "_", "-"), ".", "-"))
  value        = sensitive(local.github_environment_secrets[each.value])
  key_vault_id = azurerm_key_vault.secrets.id
  tags         = merge(local.tags, { system_environment_variable_name = each.key })
  depends_on   = [azurerm_key_vault_access_policy.principals]
  lifecycle {
    replace_triggered_by = [
      null_resource.github_secrets[each.key].triggers
    ]
  }
}

resource "null_resource" "secrets" {
  for_each = var.environment_secrets
  triggers = {
    force_recreate = sensitive(each.value)
  }
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.environment_secrets
  name         = lower(replace(replace(replace(each.key, ":", "-"), "_", "-"), ".", "-"))
  value        = sensitive(each.value)
  key_vault_id = azurerm_key_vault.secrets.id
  tags         = merge(local.tags, { system_environment_variable_name = each.key })
  depends_on   = [azurerm_key_vault_access_policy.principals]
  lifecycle {
    replace_triggered_by = [
      null_resource.secrets[each.key].triggers
    ]
  }
}


resource "azurerm_key_vault_access_policy" "principals" {
  count              = length(local.all_access_policies)
  tenant_id          = azurerm_key_vault.secrets.tenant_id
  key_vault_id       = azurerm_key_vault.secrets.id
  object_id          = local.all_access_policies[count.index].principal_id
  secret_permissions = toset([for access_policy in local.all_access_policies[count.index].actions : title(access_policy)])
}