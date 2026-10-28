variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-devops-corp-lab"
}

variable "location" {
  description = "Azure region where all resources will be provisioned"
  type        = string
  default     = "centralindia"
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "vnet-devops-corp"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets to create within the Virtual Network"
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
  default = {
    "workload" = {
      name             = "snet-workload-01"
      address_prefixes = ["10.0.1.0/24"]
    }
    "bastion" = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

variable "private_dns_zone_name" {
  description = "Name of the Azure Private DNS Zone"
  type        = string
  default     = "corp.internal"
}

variable "vms" {
  description = "Map of Linux Virtual Machines to deploy using for_each"
  type = map(object({
    vm_name              = string
    nic_name             = string
    private_ip           = string
    vm_size              = string
    admin_username       = string
    dns_record_name      = string
    install_nginx        = bool
    caching              = string
    storage_account_type = string
  }))
  default = {
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
}

variable "tags" {
  description = "Resource tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "DevOps-Lab"
    ManagedBy   = "Terraform"
    Project     = "Azure-KeyVault-PrivateDNS-Bastion"
  }
}
