# =============================================================================
# AKS Module - Azure Kubernetes Service
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

variable "aks_subnet_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "default_node_pool_vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "default_node_pool_count" {
  type    = number
  default = 2
}

variable "default_node_pool_min_count" {
  type    = number
  default = 1
}

variable "default_node_pool_max_count" {
  type    = number
  default = 5
}

variable "acr_id" {
  type        = string
  description = "ACR resource ID to grant AcrPull role"
}

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "aks-${local.name_prefix}"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    vm_size             = var.default_node_pool_vm_size
    auto_scaling_enabled = true
    min_count           = var.default_node_pool_min_count
    max_count           = var.default_node_pool_max_count
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = 50

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  monitor_metrics {}

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# NOTE: AcrPull role assignment is managed outside Terraform (SP lacks roleAssignments/write)

# Outputs
output "cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.main.node_resource_group
}
