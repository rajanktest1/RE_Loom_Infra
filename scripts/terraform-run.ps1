# =============================================================================
# Terraform Plan/Apply Wrapper (PowerShell)
# Runs terraform init + plan/apply for a target environment.
# Usage: .\terraform-run.ps1 -Environment dev -Action plan|apply
#        .\terraform-run.ps1 -Environment prod -Action plan -StorageAccount "mystorageacct"
# =============================================================================

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [ValidateSet("plan", "apply", "destroy")]
    [string]$Action,

    [string]$StorageAccount = $env:TF_STATE_STORAGE_ACCOUNT
)

$ErrorActionPreference = "Stop"

if (-not $StorageAccount) {
    throw "Storage account required. Set TF_STATE_STORAGE_ACCOUNT env var or pass -StorageAccount"
}

$EnvPath = Join-Path $PSScriptRoot ".." "terraform" "environments" $Environment
if (-not (Test-Path $EnvPath)) { throw "Environment path not found: $EnvPath" }

Write-Host "=== Terraform $Action - $Environment ===" -ForegroundColor Cyan
Write-Host "Directory: $EnvPath"
Write-Host "State Storage: $StorageAccount"
Write-Host ""

Push-Location $EnvPath
try {
    # Init
    Write-Host "Running terraform init..." -ForegroundColor Yellow
    terraform init -backend-config="storage_account_name=$StorageAccount"
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }

    # Validate
    Write-Host "Running terraform validate..." -ForegroundColor Yellow
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validate failed" }

    # Execute action
    switch ($Action) {
        "plan" {
            Write-Host "Running terraform plan..." -ForegroundColor Yellow
            terraform plan -out=tfplan
            if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }
            Write-Host ""
            Write-Host "Plan saved to tfplan. Run with -Action apply to execute." -ForegroundColor Green
        }
        "apply" {
            Write-Host "Running terraform apply..." -ForegroundColor Yellow
            if (Test-Path "tfplan") {
                terraform apply tfplan
            } else {
                terraform apply -auto-approve
            }
            if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
            Write-Host ""
            Write-Host "=== Apply Complete ===" -ForegroundColor Green
        }
        "destroy" {
            Write-Host "WARNING: This will destroy all resources in $Environment!" -ForegroundColor Red
            $Confirm = Read-Host "Type 'yes' to confirm"
            if ($Confirm -eq "yes") {
                terraform destroy -auto-approve
                if ($LASTEXITCODE -ne 0) { throw "Terraform destroy failed" }
                Write-Host "=== Destroy Complete ===" -ForegroundColor Green
            } else {
                Write-Host "Cancelled." -ForegroundColor Yellow
            }
        }
    }
}
finally {
    Pop-Location
}
