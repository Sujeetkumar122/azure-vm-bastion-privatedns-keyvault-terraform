variable "vnet_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" { type = list(string) }
variable "tags" { type = map(string); default = {} }

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

output "name" { value = azurerm_virtual_network.vnet.name }
output "id" { value = azurerm_virtual_network.vnet.id }
