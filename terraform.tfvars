resource_group_name   = "rg-devops-corp-lab"
location              = "centralindia"
vnet_name             = "vnet-devops-corp"
vnet_address_space    = ["10.0.0.0/16"]
private_dns_zone_name = "corp.internal"

subnets = {
  "workload" = {
    name             = "snet-workload-01"
    address_prefixes = ["10.0.1.0/24"]
  }
  "bastion" = {
    name             = "AzureBastionSubnet"
    address_prefixes = ["10.0.2.0/24"]
  }
}

vms = {
  "web-vm" = {
    vm_name              = "vm-web-01"
    nic_name             = "nic-web-01"
    private_ip           = "10.0.1.4"
    vm_size              = "Standard_B2s"
    admin_username       = "azureuser"
    dns_record_name      = "web"
    install_nginx        = true
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  "app-vm" = {
    vm_name              = "vm-app-02"
    nic_name             = "nic-app-02"
    private_ip           = "10.0.1.5"
    vm_size              = "Standard_B2s"
    admin_username       = "azureuser"
    dns_record_name      = "app"
    install_nginx        = false
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

tags = {
  Environment = "DevOps-Lab"
  ManagedBy   = "Terraform"
  Project     = "Azure-KeyVault-PrivateDNS-Bastion"
  Owner       = "Sujeet Kumar"
}
