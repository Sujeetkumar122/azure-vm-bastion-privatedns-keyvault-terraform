# Data Source: Azure Client Configuration (Identity of the running entity)
data "azurerm_client_config" "current" {}

# Data Source: Current Azure Subscription details
data "azurerm_subscription" "primary" {}

# Data Source: Dynamic resolution of the Workload Subnet
# Demonstrates how data blocks decouple resource creation from consumer references
data "azurerm_subnet" "workload_subnet" {
  name                 = var.subnets["workload"].name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name

  depends_on = [
    azurerm_subnet.subnets
  ]
}

# Data Source: Key Vault Secrets retrieval using for_each
# Fetches the 24-character random password from Key Vault to supply to the VM block
data "azurerm_key_vault_secret" "vm_password" {
  for_each     = var.vms
  name         = azurerm_key_vault_secret.vm_password[each.key].name
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_secret.vm_password
  ]
}
