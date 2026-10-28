# Azure Enterprise Infrastructure: VMs with Key Vault, Private DNS & Bastion via Terraform

[![Terraform](https://img.shields.io/badge/Terraform-v1.14%2B-623CE4?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/AzureRM-v3.117%2B-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Azure Key Vault](https://img.shields.io/badge/Security-Azure%20Key%20Vault-FFB900?style=for-the-badge&logo=azurekeyvault&logoColor=white)](https://azure.microsoft.com/en-us/products/key-vault)
[![Azure Bastion](https://img.shields.io/badge/Zero--Trust-Azure%20Bastion-00BCF2?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/en-us/products/azure-bastion)
[![Private DNS](https://img.shields.io/badge/Networking-Private%20DNS%20Zone-107C41?style=for-the-badge&logo=azuredevops&logoColor=white)](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

---

## 📌 Project Overview

This repository delivers an enterprise-grade Microsoft Azure Infrastructure-as-Code (IaC) solution built with **Terraform**. It demonstrates core DevOps patterns requested in production environments:
* **Dynamic Resource Provisioning with `for_each` & `map(object)`**: Scalable deployment of 2 Linux Virtual Machines and Network Interfaces without code duplication.
* **Sensitive Secret Governance**: Passwords generated using `random_password` with **24 characters** and strict cryptographic complexity, stored directly in **Azure Key Vault**.
* **Decoupled Architecture with `data` Blocks**: Password injection into VMs through `data "azurerm_key_vault_secret"` and dynamic subnet resolution through `data "azurerm_subnet"`.
* **Zero Public IP Security with Azure Bastion**: VMs are isolated in private subnets with no public IPs, accessed exclusively via Azure Bastion jump hosts.
* **Private Name Resolution with Azure Private DNS**: Full internal domain (`corp.internal`) with automatic registration and static A-records.
* **Hands-On Inter-VM Lab**: Nginx web service deployed on VM1, verified from VM2 via ICMP Ping and HTTP Curl using both Private IP and Private DNS FQDN.

---

## 🏛️ Architecture Diagram

```mermaid
flowchart TD
    subgraph Azure_Cloud["Microsoft Azure Subscription"]
        subgraph RG["Resource Group: rg-devops-corp-lab"]

            subgraph VNet["Virtual Network: vnet-devops-corp (10.0.0.0/16)"]
                subgraph BastionSubnet["AzureBastionSubnet (10.0.2.0/24)"]
                    BastionHost["Azure Bastion Host<br/>(bas-devops-lab)"]
                    BastionPIP["Public IP<br/>(pip-bastion-lab)"]
                    BastionPIP --- BastionHost
                end

                subgraph WorkloadSubnet["snet-workload-01 (10.0.1.0/24)"]
                    NSG["NSG: nsg-workload-01<br/>(Allow SSH, HTTP, ICMP)"]
                    
                    subgraph VM1["VM 1: vm-web-01"]
                        NIC1["NIC: nic-web-01<br/>10.0.1.4"]
                        OS1["Ubuntu 22.04 LTS"]
                        Nginx["Nginx Web Server (Port 80)"]
                        NIC1 --- OS1
                        OS1 --- Nginx
                    end

                    subgraph VM2["VM 2: vm-app-02"]
                        NIC2["NIC: nic-app-02<br/>10.0.1.5"]
                        OS2["Ubuntu 22.04 LTS"]
                        NIC2 --- OS2
                    end
                end
            end

            subgraph KeyVaultSystem["Azure Key Vault & Secrets"]
                KV["Azure Key Vault<br/>kv-devops-xxxx"]
                Secret1["Secret: vm-web-01-password<br/>(24-char Random)"]
                Secret2["Secret: vm-app-02-password<br/>(24-char Random)"]
                KV --- Secret1
                KV --- Secret2
            end

            subgraph DNS["Azure Private DNS Zone"]
                PrivateZone["Zone: corp.internal"]
                VNetLink["VNet Link (Registration Enabled)"]
                Record1["A-Record: web.corp.internal -> 10.0.1.4"]
                Record2["A-Record: app.corp.internal -> 10.0.1.5"]
                PrivateZone --- VNetLink
                PrivateZone --- Record1
                PrivateZone --- Record2
            end
        end
    end

    %% Access & Connectivity
    Engineer["👨‍💻 DevOps Engineer / Admin"] -->|Browser / Azure CLI SSH| BastionHost
    BastionHost -->|Secure Internal SSH (22)| VM1
    BastionHost -->|Secure Internal SSH (22)| VM2

    %% Inter-VM Communication
    VM2 -->|1. ICMP Ping: 10.0.1.4| VM1
    VM2 -->|2. DNS Query: web.corp.internal| PrivateZone
    VM2 -->|3. HTTP GET: http://web.corp.internal| Nginx

    %% Key Vault Data Block Retrieval
    KV -.->|data azurerm_key_vault_secret| VM1
    KV -.->|data azurerm_key_vault_secret| VM2

    classDef azure fill:#0B1F3A,stroke:#0078D4,stroke-width:2px,color:#fff;
    classDef security fill:#2c1b02,stroke:#d97706,stroke-width:2px,color:#fff;
    classDef networking fill:#062d1d,stroke:#059669,stroke-width:2px,color:#fff;
    classDef compute fill:#18182b,stroke:#8b5cf6,stroke-width:2px,color:#fff;

    class RG,VNet azure;
    class KeyVaultSystem,KV,Secret1,Secret2 security;
    class DNS,PrivateZone,VNetLink,Record1,Record2 networking;
    class VM1,VM2,OS1,OS2,NIC1,NIC2 compute;
```

---

## 🔑 Key Features & Technical Highlights

### 1. `for_each` and `map(object)` Implementation
Instead of writing repetitive code for each Virtual Machine and Network Interface, resources use `for_each = var.vms`:

```hcl
variable "vms" {
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
}
```

### 2. Prominent `data` Blocks
The project uses 4 essential data sources to maintain loose coupling:
1. **`data "azurerm_client_config" "current" {}`**: Extracts executing identity Tenant ID and Object ID to configure Key Vault access policies.
2. **`data "azurerm_subscription" "primary" {}`**: Validates subscription scope.
3. **`data "azurerm_subnet" "workload_subnet" {}`**: Dynamically fetches the subnet ID for NIC assignment.
4. **`data "azurerm_key_vault_secret" "vm_password" {}`**: Fetches generated passwords back from Key Vault via data block using `for_each`.

### 3. 24-Character Random Passwords in Key Vault
Passwords satisfy Azure VM requirements with high entropy:
* **Length:** 24 characters
* **Complexity:** Min 4 uppercase, min 4 lowercase, min 4 numeric, min 4 special characters (`!#$%&*()-_=+[]{}<>:?`).
* Stored in Azure Key Vault secret resources and retrieved through data blocks. No plain-text passwords in code or outputs.

### 4. Zero-Trust Access with Azure Bastion
* **Zero Public IPs:** Both VMs only have private IPs (`10.0.1.4` and `10.0.1.5`).
* **Azure Bastion Host:** Deployed in dedicated `AzureBastionSubnet` with a Standard Public IP for secure SSH access without exposing port 22 to the public internet.

### 5. Private DNS Zone & Name Resolution
* Zone name: `corp.internal`
* Linked to the VNet with `registration_enabled = true`.
* Custom A-records:
  * `web.corp.internal` ➡️ `10.0.1.4`
  * `app.corp.internal` ➡️ `10.0.1.5`

---

## 📂 Repository File Structure

```text
azure-vm-bastion-privatedns-keyvault-terraform/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml          # GitHub Actions CI for linting and security
├── environments/
│   └── dev/
│       └── main.tf                   # Multi-environment consumption of modules
├── modules/
│   ├── azurerm_bastion/              # Bastion host & public IP module
│   ├── azurerm_key_vault/            # Key Vault & random passwords module
│   ├── azurerm_private_dns/          # Private DNS Zone, VNet Link & A-records
│   ├── azurerm_resource_group/       # Resource group module
│   ├── azurerm_subnet/               # Subnets provisioning module
│   ├── azurerm_virtual_machine/      # Linux VM & NIC module
│   └── azurerm_virtual_network/      # VNet module
├── scripts/
│   ├── deploy.ps1                    # Deployment automation script
│   └── verify-connectivity.sh        # Lab verification script (Ping & Curl)
├── .gitignore                        # Git exclusion rules
├── azure-pipelines.yml               # Azure DevOps multi-stage CI pipeline
├── bastion.tf                        # Bastion host & Public IP definition
├── compute.tf                        # Linux VMs & NICs (with Nginx Cloud-Init)
├── data.tf                           # Client config, Subnet & Key Vault data blocks
├── keyvault.tf                       # Key Vault, Access Policies & 24-char secrets
├── network.tf                        # Resource Group, VNet, Subnets, NSG & rules
├── outputs.tf                        # Outputs & ready-to-run lab verification commands
├── privatedns.tf                     # Private DNS Zone, VNet Link & A-records
├── provider.tf                       # Terraform & AzureRM provider configuration
├── terraform.tfvars                  # Input parameters for lab deployment
├── variables.tf                      # Input variables definitions and types
└── README.md                         # Project documentation
```

---

## 🚀 Step-by-Step Deployment Guide

### Prerequisites
1. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated (`az login`).
2. [Terraform CLI (>= 1.5.0)](https://developer.hashicorp.com/terraform/install) installed.

### 1. Clone the Repository
```bash
git clone https://github.com/Sujeetkumar122/azure-vm-bastion-privatedns-keyvault-terraform.git
cd azure-vm-bastion-privatedns-keyvault-terraform
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review Plan
```bash
terraform plan
```

### 4. Deploy Infrastructure
```bash
terraform apply -auto-approve
```

---

## 🧪 Hands-On Lab Verification Guide

Follow these exact steps to verify the deployment:

### Step 1: Retrieve the 24-Character Password from Key Vault
Retrieve the generated passwords from Key Vault using the Azure CLI:

```bash
# Get Key Vault name from Terraform outputs
KV_NAME=$(terraform output -raw key_vault_name)

# Retrieve password for VM1
az keyvault secret show --vault-name "$KV_NAME" --name "vm-web-01-password" --query value -o tsv

# Retrieve password for VM2
az keyvault secret show --vault-name "$KV_NAME" --name "vm-app-02-password" --query value -o tsv
```

---

### Step 2: Login to VM1 via Azure Bastion & Check Nginx
Access VM1 securely through Azure Bastion:

```bash
# Connect using Azure CLI Bastion tunnel
az network bastion ssh \
  --name "bas-devops-lab" \
  --resource-group "rg-devops-corp-lab" \
  --target-resource-id $(terraform output -json virtual_machines | jq -r '."web-vm".name') \
  --auth-type password \
  --username azureuser
```
*(Or use Azure Portal: Navigate to **vm-web-01** ➡️ **Connect** ➡️ **Bastion** ➡️ enter `azureuser` and the 24-character password).*

Once logged into **VM1**, confirm Nginx status:
```bash
sudo systemctl status nginx
curl http://localhost
```

If manual installation is preferred:
```bash
sudo apt update -y
sudo apt install -y nginx
sudo systemctl enable --now nginx
echo "<h1>Hello from VM1 (vm-web-01)</h1>" | sudo tee /var/www/html/index.html
```

---

### Step 3: Login to VM2 via Azure Bastion
Open a session to **VM2** (`vm-app-02`):

```bash
az network bastion ssh \
  --name "bas-devops-lab" \
  --resource-group "rg-devops-corp-lab" \
  --target-resource-id $(terraform output -json virtual_machines | jq -r '."app-vm".name') \
  --auth-type password \
  --username azureuser
```

---

### Step 4: Test Connectivity from VM2 to VM1

From the shell inside **VM2**, run the verification tests:

#### 1. Ping VM1 using Private IP:
```bash
ping -c 4 10.0.1.4
```
*Expected Output:* `4 packets transmitted, 4 received, 0% packet loss`.

#### 2. Ping VM1 using Azure Private DNS FQDN:
```bash
ping -c 4 web.corp.internal
```
*Expected Output:* Host resolves to `10.0.1.4` and returns successful ICMP replies.

#### 3. Test HTTP Curl to Nginx Server:
```bash
curl -I http://web.corp.internal
```
*Expected Output:* `HTTP/1.1 200 OK`.

#### 4. Fetch the full web page:
```bash
curl http://web.corp.internal
```

---

### Quick Automated Lab Verification
Alternatively, copy and run the automated script inside VM2:
```bash
curl -sSL https://raw.githubusercontent.com/Sujeetkumar122/azure-vm-bastion-privatedns-keyvault-terraform/main/scripts/verify-connectivity.sh | bash
```

---

## 🧹 Clean Up & Teardown

To avoid incurring ongoing Azure costs, destroy all provisioned resources:

```bash
terraform destroy -auto-approve
```

---

## 💡 Interview Concepts & Best Practices

| Question | Answer & Best Practice |
|---|---|
| **Why use `for_each` over `count`?** | `count` references resources by numeric index (`[0]`, `[1]`). Removing an element from the middle shifts all subsequent indices, causing Terraform to recreate resources unintentionally. `for_each` tracks resources by map keys (`["web-vm"]`), preserving state integrity when adding or removing entries. |
| **Why use `data` blocks for passwords and subnets?** | Data blocks establish loose coupling. Subnet lookup via `data "azurerm_subnet"` allows networking and compute lifecycle management to remain independent. Retrieving passwords via `data "azurerm_key_vault_secret"` demonstrates compliance with zero-hardcoded secret policies. |
| **Why is Azure Bastion preferred over Public IPs?** | Bastion provides browser-based TLS jump-host connectivity directly inside the virtual network. No VM requires a public IP, eliminating attack vectors like brute-force SSH/RDP scans from the public internet. |
| **What does `registration_enabled = true` do in Private DNS?** | Automatically creates and maintains DNS lifecycle records (A-records and PTR records) for VMs provisioned within the linked Virtual Network. |

---

## 👤 Author

* **Sujeet Kumar** - [GitHub Profile](https://github.com/Sujeetkumar122)
* Project: Azure Cloud Platform Automation with Terraform
