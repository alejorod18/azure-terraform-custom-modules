output "connection_string" {
  value     = module.app_configuration.primary_read_key
  sensitive = true
}