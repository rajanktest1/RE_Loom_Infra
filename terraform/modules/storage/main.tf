# =============================================================================
# Storage Module - Azure Blob Storage (documents, uploads)
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

variable "containers" {
  type    = list(string)
  default = ["documents", "uploads", "exports"]
}

resource "random_id" "storage_suffix" {
  byte_length = 3
}

locals {
  # Storage account names: 3-24 lowercase alphanumeric, globally unique
  storage_name = substr("st${replace(var.project_name, "-", "")}${var.environment}${random_id.storage_suffix.hex}", 0, 24)
}

resource "azurerm_storage_account" "main" {
  name                     = local.storage_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "PUT", "POST"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_storage_container" "containers" {
  for_each = toset(var.containers)

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_account_id" {
  value = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_access_key" {
  value     = azurerm_storage_account.main.primary_access_key
  sensitive = true
}
