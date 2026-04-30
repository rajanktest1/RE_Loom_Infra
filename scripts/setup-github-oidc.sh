#!/bin/bash
# =============================================================================
# Setup GitHub OIDC Federation for Azure
# Creates an App Registration with federated credentials for both repos.
# Prerequisites: az cli logged in with owner/contributor access.
# =============================================================================

set -euo pipefail

APP_NAME="github-realestate-deploy"
GITHUB_ORG="${1:?Usage: $0 <github-org-or-username>}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "=== Setting up OIDC Federation ==="
echo "App Name: $APP_NAME"
echo "GitHub Org: $GITHUB_ORG"
echo "Subscription: $SUBSCRIPTION_ID"
echo ""

# Create App Registration
echo "Creating App Registration..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
echo "App (Client) ID: $APP_ID"

# Create Service Principal
echo "Creating Service Principal..."
SP_OBJECT_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
echo "Service Principal Object ID: $SP_OBJECT_ID"

# Assign Contributor role on the subscription
echo "Assigning Contributor role..."
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role Contributor \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output none

# Get Tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Add federated credential for InfraRepo (main branch)
echo "Adding federated credential for InfraRepo:main..."
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "infra-repo-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG"'/InfraRepo:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}' --output none

# Add federated credential for InfraRepo (pull requests)
echo "Adding federated credential for InfraRepo:pull_request..."
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "infra-repo-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG"'/InfraRepo:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}' --output none

# Add federated credential for AppRepo (main branch - for ACR push)
echo "Adding federated credential for AppRepo:main..."
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "app-repo-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG"'/AppRepo:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}' --output none

# Add federated credential for InfraRepo environments
for ENV in dev staging prod; do
  echo "Adding federated credential for InfraRepo:environment:$ENV..."
  az ad app federated-credential create --id "$APP_ID" --parameters '{
    "name": "infra-repo-env-'"$ENV"'",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG"'/InfraRepo:environment:'"$ENV"'",
    "audiences": ["api://AzureADTokenExchange"]
  }' --output none
done

echo ""
echo "=== OIDC Setup Complete ==="
echo ""
echo "Add these as GitHub Repository Secrets (both repos):"
echo ""
echo "  AZURE_CLIENT_ID:       $APP_ID"
echo "  AZURE_TENANT_ID:       $TENANT_ID"
echo "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Add to GitHub Repository Variables (AppRepo):"
echo "  ACR_NAME: <your-acr-name> (created by Terraform)"
echo ""
