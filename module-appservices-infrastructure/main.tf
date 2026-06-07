resource "azurerm_service_plan" "app_service" {
  name                = "asp-${var.identifier}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  tags                = data.azurerm_resource_group.rg.tags
  sku_name            = var.sku_name
}
