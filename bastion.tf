# Public IP for Azure Bastion (Standard SKU required by Azure Bastion)
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Bastion Host inside AzureBastionSubnet
resource "azurerm_bastion_host" "bastion" {
  name                = "bas-devops-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.subnets["bastion"].id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  depends_on = [
    azurerm_subnet.subnets,
    azurerm_public_ip.bastion_pip
  ]
}
