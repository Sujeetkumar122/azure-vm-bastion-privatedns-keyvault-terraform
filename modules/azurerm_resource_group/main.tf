variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string); default = {} }

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

output "name" { value = azurerm_resource_group.rg.name }
output "location" { value = azurerm_resource_group.rg.location }
