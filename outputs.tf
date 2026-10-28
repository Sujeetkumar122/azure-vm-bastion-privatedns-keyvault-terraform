output "resource_group_name" {
  description = "The name of the Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_secret_names" {
  description = "Key Vault secret names for each VM password"
  value = {
    for k, v in azurerm_key_vault_secret.vm_password : k => v.name
  }
}

output "private_dns_zone" {
  description = "The Private DNS Zone name"
  value       = azurerm_private_dns_zone.zone.name
}

output "virtual_machines" {
  description = "Provisioned VM summary including IPs and DNS records"
  value = {
    for k, vm in var.vms : k => {
      name        = vm.vm_name
      private_ip  = vm.private_ip
      dns_fqdn    = "."
      username    = vm.admin_username
      secret_name = azurerm_key_vault_secret.vm_password[k].name
    }
  }
}

output "bastion_name" {
  description = "Azure Bastion Host name"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_public_ip" {
  description = "Azure Bastion Public IP"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "lab_verification_instructions" {
  description = "Step-by-step commands to retrieve passwords, connect via Bastion, and verify ping & curl"
  value = {
    "1_fetch_vm1_password" = "az keyvault secret show --vault-name  --name vm-web-01-password --query value -o tsv"
    "2_fetch_vm2_password" = "az keyvault secret show --vault-name  --name vm-app-02-password --query value -o tsv"
    "3_bastion_ssh_vm1"    = "az network bastion ssh --name  --resource-group  --target-resource-id  --auth-type password --username azureuser"
    "4_bastion_ssh_vm2"    = "az network bastion ssh --name  --resource-group  --target-resource-id  --auth-type password --username azureuser"
    "5_vm2_ping_test"      = "ping -c 4 web."
    "6_vm2_curl_test"      = "curl -I http://web."
  }
}
