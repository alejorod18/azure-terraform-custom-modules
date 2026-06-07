output "administrator_login_password" {
  value     = module.cosmos_pg.administrator_login_password
  sensitive = true
}

output "servers_fqdn" {
  value     = module.cosmos_pg.servers_fqdn
  sensitive = true
}

output "users_credentials" {
  value     = module.cosmos_pg.users_credentials
  sensitive = true
}