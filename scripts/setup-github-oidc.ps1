# =============================================================================
# Setup GitHub OIDC Federation for Azure (PowerShell)
# Creates an App Registration with federated credentials for both repos.
# Prerequisites: Azure CLI logged in with owner/contributor access.
# Usage: .\setup-github-oidc.ps1 -GitHubOrg <your-github-username-or-org>
# =============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubOrg
)

$ErrorActionPreference = "Stop"

$AppName = "github-realestate-deploy"
$SubscriptionId = (az account show --query id -o tsv)
if ($LASTEXITCODE -ne 0) { throw "Failed to get subscription ID. Are you logged in?" }

Write-Host "=== Setting up OIDC Federation ===" -ForegroundColor Cyan
Write-Host "App Name: $AppName"
Write-Host "GitHub Org: $GitHubOrg"
Write-Host "Subscription: $SubscriptionId"
Write-Host ""

# Create App Registration
Write-Host "Creating App Registration..." -ForegroundColor Yellow
$AppId = (az ad app create --display-name $AppName --query appId -o tsv)
if ($LASTEXITCODE -ne 0) { throw "Failed to create app registration" }
Write-Host "App (Client) ID: $AppId"

# Create Service Principal
Write-Host "Creating Service Principal..." -ForegroundColor Yellow
$SpObjectId = (az ad sp create --id $AppId --query id -o tsv)
if ($LASTEXITCODE -ne 0) { throw "Failed to create service principal" }
Write-Host "Service Principal Object ID: $SpObjectId"

# Assign Contributor role on the subscription
Write-Host "Assigning Contributor role..." -ForegroundColor Yellow
az role assignment create `
  --assignee-object-id $SpObjectId `
  --assignee-principal-type ServicePrincipal `
  --role Contributor `
  --scope "/subscriptions/$SubscriptionId" `
  --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to assign role" }

# Get Tenant ID
$TenantId = (az account show --query tenantId -o tsv)

# Add federated credential for InfraRepo (main branch)
Write-Host "Adding federated credential for InfraRepo:main..." -ForegroundColor Yellow
$InfraMainParams = @{
    name      = "infra-repo-main"
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = "repo:${GitHubOrg}/InfraRepo:ref:refs/heads/main"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Compress
az ad app federated-credential create --id $AppId --parameters $InfraMainParams --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to add InfraRepo:main credential" }

# Add federated credential for InfraRepo (pull requests)
Write-Host "Adding federated credential for InfraRepo:pull_request..." -ForegroundColor Yellow
$InfraPrParams = @{
    name      = "infra-repo-pr"
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = "repo:${GitHubOrg}/InfraRepo:pull_request"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Compress
az ad app federated-credential create --id $AppId --parameters $InfraPrParams --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to add InfraRepo:pull_request credential" }

# Add federated credential for AppRepo (main branch - for ACR push)
Write-Host "Adding federated credential for AppRepo:main..." -ForegroundColor Yellow
$AppMainParams = @{
    name      = "app-repo-main"
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = "repo:${GitHubOrg}/AppRepo:ref:refs/heads/main"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Compress
az ad app federated-credential create --id $AppId --parameters $AppMainParams --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to add AppRepo:main credential" }

# Add federated credential for InfraRepo environments
foreach ($Env in @("dev", "staging", "prod")) {
    Write-Host "Adding federated credential for InfraRepo:environment:$Env..." -ForegroundColor Yellow
    $EnvParams = @{
        name      = "infra-repo-env-$Env"
        issuer    = "https://token.actions.githubusercontent.com"
        subject   = "repo:${GitHubOrg}/InfraRepo:environment:${Env}"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress
    az ad app federated-credential create --id $AppId --parameters $EnvParams --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to add InfraRepo:environment:$Env credential" }
}

Write-Host ""
Write-Host "=== OIDC Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Add these as GitHub Repository Secrets (both repos):"
Write-Host ""
Write-Host "  AZURE_CLIENT_ID:       $AppId" -ForegroundColor White
Write-Host "  AZURE_TENANT_ID:       $TenantId" -ForegroundColor White
Write-Host "  AZURE_SUBSCRIPTION_ID: $SubscriptionId" -ForegroundColor White
Write-Host ""
Write-Host "Add to GitHub Repository Variables (AppRepo):"
Write-Host "  ACR_NAME: <your-acr-name> (created by Terraform)" -ForegroundColor White
Write-Host ""
