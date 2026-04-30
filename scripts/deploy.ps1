# =============================================================================
# Deploy to AKS (PowerShell)
# Deploys application to a target AKS environment using Kustomize.
# Prerequisites: az cli logged in, kubectl configured.
# Usage: .\deploy.ps1 -Environment dev -ImageTag "sha-abc1234"
# =============================================================================

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$ImageTag
)

$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-realestate-$Environment"
$ClusterName = "aks-realestate-$Environment"

Write-Host "=== Deploying to AKS ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment"
Write-Host "Cluster: $ClusterName"
Write-Host "Image Tag: $ImageTag"
Write-Host ""

# Get AKS credentials
Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials `
  --resource-group $ResourceGroup `
  --name $ClusterName `
  --overwrite-existing
if ($LASTEXITCODE -ne 0) { throw "Failed to get AKS credentials" }

# Navigate to overlay
$OverlayPath = Join-Path $PSScriptRoot ".." "k8s" "overlays" $Environment
if (-not (Test-Path $OverlayPath)) { throw "Overlay path not found: $OverlayPath" }

# Update image tags
Write-Host "Updating image tags..." -ForegroundColor Yellow
Push-Location $OverlayPath
try {
    $Services = @("gateway", "auth-service", "inventory-service", "supply-chain-service", "crm-service", "notification-service", "document-service", "web")
    foreach ($Svc in $Services) {
        kustomize edit set image "IMAGE_PLACEHOLDER=acrealestate${Environment}.azurecr.io/realestate/${Svc}:${ImageTag}"
    }
}
finally {
    Pop-Location
}

# Apply with Kustomize
Write-Host "Applying manifests..." -ForegroundColor Yellow
kubectl apply -k $OverlayPath
if ($LASTEXITCODE -ne 0) { throw "Failed to apply manifests" }

# Wait for rollouts
Write-Host ""
Write-Host "Waiting for rollouts..." -ForegroundColor Yellow
$Deployments = @("gateway", "auth-service", "inventory-service", "supply-chain-service", "crm-service", "notification-service", "document-service", "web")
foreach ($Deploy in $Deployments) {
    Write-Host "  Waiting for $Deploy..." -ForegroundColor Gray
    kubectl rollout status "deployment/$Deploy" -n realestate --timeout=300s 2>$null
}

# Summary
Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "--- Pod Status ---" -ForegroundColor Cyan
kubectl get pods -n realestate -o wide
Write-Host ""
Write-Host "--- Ingress ---" -ForegroundColor Cyan
kubectl get ingress -n realestate
