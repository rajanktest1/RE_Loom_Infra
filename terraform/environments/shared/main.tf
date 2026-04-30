# =============================================================================
# Shared Infrastructure - Resources shared across all environments
# Provisioned ONCE before any environment. Contains:
#   - Azure Container Registry (single ACR for all envs)
#   - Shared resource group
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-realestate-tfstate"
    storage_account_name = ""
    container_name       = "tfstate"
    key                  = "shared.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "project_name" {
  type    = string
  default = "realestate"
}

variable "acr_sku" {
  type    = string
  default = "Standard"
}

# =============================================================================
# Shared Resource Group
# =============================================================================
resource "azurerm_resource_group" "shared" {
  name     = "rg-${var.project_name}-shared"
  location = var.location

  tags = {
    environment = "shared"
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# =============================================================================
# Shared ACR - Single registry used by all environments
# =============================================================================
resource "azurerm_container_registry" "shared" {
  name                = "acr${replace(var.project_name, "-", "")}shared"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = {
    environment = "shared"
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# =============================================================================
# Outputs
# =============================================================================
output "resource_group_name" {
  value = azurerm_resource_group.shared.name
}

output "acr_id" {
  value = azurerm_container_registry.shared.id
}

output "acr_name" {
  value = azurerm_container_registry.shared.name
}

output "acr_login_server" {
  value = azurerm_container_registry.shared.login_server
}
