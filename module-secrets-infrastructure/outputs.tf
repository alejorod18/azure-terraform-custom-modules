output "repository" {
  value = local.github_repository_name
}

locals {
  secrets_output = merge(
    merge([for secret in azurerm_key_vault_secret.github_secrets : { (secret.tags["system_environment_variable_name"]) = secret.id }]...),
    merge([for secret in azurerm_key_vault_secret.secrets : { (secret.tags["system_environment_variable_name"]) = secret.id }]...)
  )
}

output "secrets" {
  value = local.secrets_output
}

output "id" {
  value = azurerm_key_vault.secrets.id
}

output "vault_uri" {
  value = azurerm_key_vault.secrets.vault_uri
}
