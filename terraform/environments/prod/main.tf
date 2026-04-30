# =============================================================================
# Production Environment - Main Configuration
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
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-realestate-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project_name        = var.project_name
}

module "acr" {
  source = "../../modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project_name        = var.project_name
  sku                 = var.acr_sku
}

module "aks" {
  source = "../../modules/aks"

  resource_group_name         = azurerm_resource_group.main.name
  location                    = var.location
  environment                 = var.environment
  project_name                = var.project_name
  aks_subnet_id               = module.networking.aks_subnet_id
  kubernetes_version          = var.kubernetes_version
  default_node_pool_vm_size   = var.aks_node_vm_size
  default_node_pool_min_count = var.aks_node_min_count
  default_node_pool_max_count = var.aks_node_max_count
  acr_id                      = module.acr.acr_id
}

module "cosmosdb" {
  source = "../../modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project_name        = var.project_name
}

module "redis" {
  source = "../../modules/redis"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project_name        = var.project_name
  sku_name            = var.redis_sku
  capacity            = var.redis_capacity
}

module "storage" {
  source = "../../modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project_name        = var.project_name
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name                = azurerm_resource_group.main.name
  location                           = var.location
  environment                        = var.environment
  project_name                       = var.project_name
  tenant_id                          = data.azurerm_client_config.current.tenant_id
  aks_kubelet_identity_object_id     = module.aks.kubelet_identity_object_id
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project_name        = var.project_name
  aks_cluster_id      = module.aks.cluster_id
  retention_in_days   = 90
}

resource "azurerm_key_vault_secret" "cosmosdb_connection" {
  name         = "cosmosdb-connection-string"
  value        = module.cosmosdb.cosmosdb_connection_string
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "redis_connection" {
  name         = "redis-connection-string"
  value        = module.redis.redis_connection_string
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-access-key"
  value        = module.storage.primary_access_key
  key_vault_id = module.keyvault.key_vault_id
}
