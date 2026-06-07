output "servers_fqdn" {
  description = "The servers fqdn"
  value       = azurerm_mssql_server.primary.fully_qualified_domain_name
  sensitive   = true
}

output "administrator_login_password" {
  description = "The administrator login password"
  value       = random_password.administrator_login_password.result
  sensitive   = true
}

output "users_credentials" {
  description = "The users credentials"
  value       = {}
  sensitive   = true
}
