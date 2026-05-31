# =============================================================================
# Key Vault Module
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

variable "tenant_id" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  kv_name     = var.name_suffix != "" ? "kv-${local.name_prefix}-${var.name_suffix}" : "kv-${local.name_prefix}"
}

resource "azurerm_key_vault" "main" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  rbac_authorization_enabled = true

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# NOTE: Key Vault Secrets User role assignment is managed outside Terraform (SP lacks roleAssignments/write)

output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}
