variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "project_name" {
  type    = string
  default = "realestate"
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "aks_node_min_count" {
  type    = number
  default = 1
}

variable "aks_node_max_count" {
  type    = number
  default = 3
}

variable "redis_sku" {
  type    = string
  default = "Basic"
}

variable "redis_capacity" {
  type    = number
  default = 0
}
