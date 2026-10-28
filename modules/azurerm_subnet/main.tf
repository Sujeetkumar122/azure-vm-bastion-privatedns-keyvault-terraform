variable "resource_group_name" { type = string }
variable "virtual_network_name" { type = string }
variable "subnets" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = each.value.address_prefixes
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnet : k => v.id }
}
