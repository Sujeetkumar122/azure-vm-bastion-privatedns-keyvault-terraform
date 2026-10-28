variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tenant_id" { type = string }
variable "object_id" { type = string }
variable "vms" { type = any }
variable "tags" { type = map(string); default = {} }

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

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

resource "azurerm_key_vault" "kv" {
  name                       = "kv-devops-${random_string.kv_suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions    = ["Get", "List", "Create", "Delete", "Update"]
  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

resource "azurerm_key_vault_secret" "vm_password" {
  for_each     = var.vms
  name         = "${each.value.vm_name}-password"
  value        = random_password.vm_password[each.key].result
  key_vault_id = azurerm_key_vault.kv.id
  tags         = var.tags

  depends_on = [azurerm_key_vault_access_policy.client]
}

output "key_vault_id" { value = azurerm_key_vault.kv.id }
output "key_vault_name" { value = azurerm_key_vault.kv.name }
output "secret_names" {
  value = { for k, v in azurerm_key_vault_secret.vm_password : k => v.name }
}
