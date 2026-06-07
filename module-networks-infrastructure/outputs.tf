locals {
  nat_gateway_ip = var.enable_nat_gateway ? azurerm_public_ip.net[0].ip_address : null
}


output "subnet_id" {
  value = azurerm_subnet.net.id
}

output "nat_gateway_ip" {
  value = local.nat_gateway_ip
}