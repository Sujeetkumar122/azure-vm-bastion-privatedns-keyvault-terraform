# Network Interfaces created using for_each over VMs map
# Subnet ID dynamically fetched via data.azurerm_subnet.workload_subnet
resource "azurerm_network_interface" "nics" {
  for_each            = var.vms
  name                = each.value.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.workload_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
  }
}

# Cloud-Init script to configure Nginx on VM1 automatically
locals {
  nginx_cloud_init = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl enable --now nginx
              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>DevOps Lab - VM1 Nginx Server</title>
                <style>
                  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0f172a; color: #f8fafc; text-align: center; padding-top: 80px; }
                  .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; display: inline-block; padding: 40px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); max-width: 600px; }
                  h1 { color: #38bdf8; margin-bottom: 10px; }
                  .badge { background: #10b981; color: #022c22; font-weight: bold; padding: 6px 14px; border-radius: 20px; display: inline-block; margin-top: 15px; }
                  .code { background: #090d16; padding: 8px 12px; border-radius: 6px; font-family: monospace; color: #a5f3fc; }
                </style>
              </head>
              <body>
                <div class="card">
                  <h1>🚀 VM1 Nginx Web Server Active</h1>
                  <p>Provisioned automatically using <b>Terraform for_each</b> & <b>Azure Key Vault</b></p>
                  <p>Host Private FQDN: <span class="code">web.corp.internal</span></p>
                  <p>Private IP: <span class="code">10.0.1.4</span></p>
                  <div class="badge">HTTP 200 OK - Lab Ready</div>
                </div>
              </body>
              </html>
              HTML
              systemctl restart nginx
              EOF
}

# Linux Virtual Machines provisioned with for_each
# Password fetched dynamically from Key Vault data block
resource "azurerm_linux_virtual_machine" "vms" {
  for_each            = var.vms
  name                = each.value.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = each.value.vm_size
  admin_username      = each.value.admin_username

  # Dynamic retrieval of the 24-character random password from Key Vault data block!
  admin_password                  = data.azurerm_key_vault_secret.vm_password[each.key].value
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nics[each.key].id
  ]

  # Cloud-init custom_data conditionally applied for Nginx
  custom_data = each.value.install_nginx ? base64encode(local.nginx_cloud_init) : null

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

  depends_on = [
    data.azurerm_key_vault_secret.vm_password,
    azurerm_network_interface.nics
  ]
}
