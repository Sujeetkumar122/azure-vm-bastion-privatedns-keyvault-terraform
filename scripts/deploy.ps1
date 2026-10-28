<#
.SYNOPSIS
    Automated deployment script for the Azure Terraform infrastructure.
.DESCRIPTION
    Checks Azure CLI login, initializes Terraform, validates configuration, and applies infra.
#>

[CmdletBinding()]
param(
    [switch]$AutoApprove = $false,
    [switch]$Destroy = $false
)

Write-Host "=== 🚀 Azure Terraform Bastion, Private DNS & Key Vault Lab ===" -ForegroundColor Cyan

# Check Azure Login
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✔ Logged in as: $($account.user.name) (Subscription: $($account.name))" -ForegroundColor Green
} catch {
    Write-Error "Please run 'az login' first to authenticate to Azure."
    exit 1
}

# Terraform Init
Write-Host "`n=== 📦 Initializing Terraform ===" -ForegroundColor Cyan
terraform init

# Terraform Validate
Write-Host "`n=== 🔍 Validating Terraform Configuration ===" -ForegroundColor Cyan
terraform validate

if ($Destroy) {
    Write-Host "`n=== ⚠️ Destroying Infrastructure ===" -ForegroundColor Red
    if ($AutoApprove) {
        terraform destroy -auto-approve
    } else {
        terraform destroy
    }
    exit 0
}

# Terraform Plan
Write-Host "`n=== 📋 Generating Execution Plan ===" -ForegroundColor Cyan
terraform plan -out=tfplan

# Terraform Apply
Write-Host "`n=== 🚀 Applying Infrastructure ===" -ForegroundColor Cyan
if ($AutoApprove) {
    terraform apply -auto-approve tfplan
} else {
    $confirm = Read-Host "Do you want to apply this plan? (yes/no)"
    if ($confirm -eq "yes") {
        terraform apply tfplan
    } else {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
    }
}
