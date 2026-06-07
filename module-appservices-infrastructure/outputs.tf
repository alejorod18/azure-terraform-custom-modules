output "web_apps_hostnames" {
  value = {
    for name, web_app in azurerm_linux_web_app.app_service : name => web_app.default_hostname
  }
  description = "The hostnames of the web apps."
}