output "test" {
  value = module.sync_github_to_keyvault.secrets
}

output "repository_name" {
  value = module.sync_github_to_keyvault.repository
}

output "secrets" {
  value = module.sync_github_to_keyvault.secrets
}