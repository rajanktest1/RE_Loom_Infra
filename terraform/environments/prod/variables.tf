variable "environment" {
  type    = string
  default = "prod"
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
  default = "Standard_D4s_v3"
}

variable "aks_node_min_count" {
  type    = number
  default = 3
}

variable "aks_node_max_count" {
  type    = number
  default = 10
}

variable "acr_sku" {
  type    = string
  default = "Premium"
}

variable "redis_sku" {
  type    = string
  default = "Premium"
}

variable "redis_capacity" {
  type    = number
  default = 1
}
