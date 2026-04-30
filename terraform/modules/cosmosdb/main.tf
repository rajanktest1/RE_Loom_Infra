# =============================================================================
# CosmosDB Module - MongoDB API
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

variable "throughput" {
  type    = number
  default = 400
}

variable "databases" {
  type    = list(string)
  default = ["auth", "inventory", "supplychain", "crm"]
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_cosmosdb_mongo_database" "dbs" {
  for_each = toset(var.databases)

  name                = "realestate-${each.key}"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

output "cosmosdb_connection_string" {
  value     = azurerm_cosmosdb_account.main.primary_mongodb_connection_string
  sensitive = true
}

output "cosmosdb_account_name" {
  value = azurerm_cosmosdb_account.main.name
}

output "cosmosdb_id" {
  value = azurerm_cosmosdb_account.main.id
}
