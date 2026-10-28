# Azure Private DNS Zone
resource "azurerm_private_dns_zone" "zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Private DNS Zone Virtual Network Link with Auto-Registration enabled
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "link-"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true
  tags                  = var.tags
}

# Dedicated A-records for each VM provisioned with for_each
resource "azurerm_private_dns_a_record" "vm_records" {
  for_each            = var.vms
  name                = each.value.dns_record_name
  zone_name           = azurerm_private_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [each.value.private_ip]
  tags                = var.tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.vnet_link
  ]
}
