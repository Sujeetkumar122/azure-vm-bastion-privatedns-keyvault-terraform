# Random string for unique Key Vault naming
resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generate 24-character random password for each VM using for_each
resource "random_password" "vm_password" {
  for_each         = var.vms
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
  min_special      = 4
}

# Azure Key Vault Deployment
resource "azurerm_key_vault" "kv" {
  name                       = "kv-devops-"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = false

  tags = var.tags
}

# Key Vault Access Policy for Terraform identity
resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# Store 24-character random password secrets in Key Vault for each VM
resource "azurerm_key_vault_secret" "vm_password" {
  for_each     = var.vms
  name         = "-password"
  value        = random_password.vm_password[each.key].result
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"

  tags = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.client
  ]
}
