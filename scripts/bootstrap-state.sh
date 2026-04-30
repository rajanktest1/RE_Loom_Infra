#!/bin/bash
# =============================================================================
# Bootstrap Terraform State Backend
# Run ONCE to create the storage account for remote state.
# Prerequisites: az cli logged in, subscription selected.
# =============================================================================

set -euo pipefail

RESOURCE_GROUP="rg-realestate-tfstate"
LOCATION="centralindia"
STORAGE_ACCOUNT="strealestatestate$(openssl rand -hex 3)"
CONTAINER_NAME="tfstate"

echo "=== Creating Terraform State Backend ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container: $CONTAINER_NAME"
echo ""

# Create Resource Group
echo "Creating resource group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# Create Storage Account
echo "Creating storage account..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

# Create Blob Container
echo "Creating blob container..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --output none

# Enable versioning for state protection
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --output none

echo ""
echo "=== State Backend Created Successfully ==="
echo ""
echo "Add these values to your terraform/environments/*/backend.tf:"
echo ""
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER_NAME\""
echo "  key                  = \"<env>.terraform.tfstate\""
echo ""
echo "Storage Account: $STORAGE_ACCOUNT"
echo ""
