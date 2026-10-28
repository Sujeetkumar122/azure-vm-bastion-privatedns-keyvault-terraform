variable "resource_group_name" { type = string }
variable "zone_name" { type = string }
variable "vnet_id" { type = string }
variable "vms" { type = any }
variable "tags" { type = map(string); default = {} }

resource "azurerm_private_dns_zone" "zone" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "link-${var.zone_name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = true
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "records" {
  for_each            = var.vms
  name                = each.value.dns_record_name
  zone_name           = azurerm_private_dns_zone.zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [each.value.private_ip]
  tags                = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.link]
}

output "zone_name" { value = azurerm_private_dns_zone.zone.name }
