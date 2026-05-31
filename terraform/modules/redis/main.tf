# =============================================================================
# Redis Module - Azure Managed Redis
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

variable "sku_name" {
  type    = string
  default = "Balanced_B0"
}

variable "family" {
  type    = string
  default = ""
}

variable "capacity" {
  type    = number
  default = 0
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_managed_redis" "main" {
  name                = "redis-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  default_database {
    access_keys_authentication_enabled = true
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

output "redis_hostname" {
  value = azurerm_managed_redis.main.hostname
}

output "redis_port" {
  value = azurerm_managed_redis.main.default_database[0].port
}

output "redis_primary_key" {
  value     = azurerm_managed_redis.main.default_database[0].primary_access_key
  sensitive = true
}

output "redis_connection_string" {
  value     = "rediss://:${azurerm_managed_redis.main.default_database[0].primary_access_key}@${azurerm_managed_redis.main.hostname}:${azurerm_managed_redis.main.default_database[0].port}"
  sensitive = true
}
