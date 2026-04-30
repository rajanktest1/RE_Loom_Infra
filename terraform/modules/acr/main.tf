# =============================================================================
# ACR Module - Azure Container Registry
# =============================================================================

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "realestate"
}

variable "sku" {
  type    = string
  default = "Basic"
}

locals {
  # ACR names must be alphanumeric only
  acr_name = "acr${replace(var.project_name, "-", "")}${var.environment}"
}

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

output "acr_id" {
  value = azurerm_container_registry.main.id
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}
