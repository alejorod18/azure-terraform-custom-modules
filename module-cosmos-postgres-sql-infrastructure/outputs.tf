
output "servers_fqdn" {
  description = "The servers fqdn"
  value       = azurerm_cosmosdb_postgresql_cluster.sql.servers[0].fqdn
  sensitive   = true
}

output "administrator_login_password" {
  description = "The administrator login password"
  value       = azurerm_cosmosdb_postgresql_cluster.sql.administrator_login_password
  sensitive   = true
}

output "users_credentials" {
  description = "The users credentials"
  value = {
    for user in var.users_names_list : user => random_password.roles_passwords[user].result
  }
  sensitive = true
}
