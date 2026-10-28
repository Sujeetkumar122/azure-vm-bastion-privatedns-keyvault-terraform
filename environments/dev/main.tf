module "resource_group" {
  source              = "../../modules/azurerm_resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

module "virtual_network" {
  source              = "../../modules/azurerm_virtual_network"
  vnet_name           = var.vnet_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

module "subnets" {
  source               = "../../modules/azurerm_subnet"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.virtual_network.name
  subnets              = var.subnets
}

data "azurerm_client_config" "current" {}

module "key_vault" {
  source              = "../../modules/azurerm_key_vault"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  vms                 = var.vms
  tags                = var.tags
}

module "bastion" {
  source              = "../../modules/azurerm_bastion"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.subnets.subnet_ids["bastion"]
  tags                = var.tags
}

module "private_dns" {
  source              = "../../modules/azurerm_private_dns"
  resource_group_name = module.resource_group.name
  zone_name           = var.private_dns_zone_name
  vnet_id             = module.virtual_network.id
  vms                 = var.vms
  tags                = var.tags
}

module "virtual_machines" {
  source              = "../../modules/azurerm_virtual_machine"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.subnets.subnet_ids["workload"]
  key_vault_id        = module.key_vault.key_vault_id
  vms                 = var.vms
  tags                = var.tags

  depends_on = [module.key_vault]
}
