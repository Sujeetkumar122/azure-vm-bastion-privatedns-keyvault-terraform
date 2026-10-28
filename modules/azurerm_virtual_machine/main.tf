variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" { type = string }
variable "key_vault_id" { type = string }
variable "vms" { type = any }
variable "tags" { type = map(string); default = {} }

# Data block for reading Key Vault Secret
data "azurerm_key_vault_secret" "vm_password" {
  for_each     = var.vms
  name         = "${each.value.vm_name}-password"
  key_vault_id = var.key_vault_id
}

resource "azurerm_network_interface" "nics" {
  for_each            = var.vms
  name                = each.value.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
  }
}

locals {
  nginx_init = <<-EOF
              #!/bin/bash
              apt-get update -y && apt-get install -y nginx
              systemctl enable --now nginx
              echo "<h1>VM1 Nginx Active</h1>" > /var/www/html/index.html
              EOF
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each                        = var.vms
  name                            = each.value.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = each.value.vm_size
  admin_username                  = each.value.admin_username
  admin_password                  = data.azurerm_key_vault_secret.vm_password[each.key].value
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nics[each.key].id]
  custom_data           = each.value.install_nginx ? base64encode(locals.nginx_init) : null

  os_disk {
    caching              = each.value.caching
    storage_account_type = each.value.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}

output "vm_ids" {
  value = { for k, v in azurerm_linux_virtual_machine.vms : k => v.id }
}
