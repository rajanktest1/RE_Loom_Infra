# =============================================================================
# Bootstrap Terraform State Backend (PowerShell)
# Run ONCE to create the storage account for remote state.
# Prerequisites: Azure CLI logged in, subscription selected.
# Usage: .\bootstrap-state.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-realestate-tfstate"
$Location = "centralindia"
$RandomSuffix = -join ((48..57) + (97..102) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$StorageAccount = "strealestatestate$RandomSuffix"
$ContainerName = "tfstate"

Write-Host "=== Creating Terraform State Backend ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location: $Location"
Write-Host "Storage Account: $StorageAccount"
Write-Host "Container: $ContainerName"
Write-Host ""

# Create Resource Group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create `
  --name $ResourceGroup `
  --location $Location `
  --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group" }

# Create Storage Account
Write-Host "Creating storage account..." -ForegroundColor Yellow
az storage account create `
  --name $StorageAccount `
  --resource-group $ResourceGroup `
  --location $Location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false `
  --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to create storage account" }

# Create Blob Container
Write-Host "Creating blob container..." -ForegroundColor Yellow
az storage container create `
  --name $ContainerName `
  --account-name $StorageAccount `
  --auth-mode login `
  --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to create blob container" }

# Enable versioning for state protection
Write-Host "Enabling blob versioning..." -ForegroundColor Yellow
az storage account blob-service-properties update `
  --account-name $StorageAccount `
  --resource-group $ResourceGroup `
  --enable-versioning true `
  --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to enable versioning" }

Write-Host ""
Write-Host "=== State Backend Created Successfully ===" -ForegroundColor Green
Write-Host ""
Write-Host "Add these values to your terraform/environments/*/backend.tf:"
Write-Host ""
Write-Host "  resource_group_name  = `"$ResourceGroup`""
Write-Host "  storage_account_name = `"$StorageAccount`""
Write-Host "  container_name       = `"$ContainerName`""
Write-Host "  key                  = `"<env>.terraform.tfstate`""
Write-Host ""
Write-Host "Storage Account: $StorageAccount" -ForegroundColor Green
Write-Host ""
