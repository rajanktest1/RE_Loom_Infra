variable "environment" {
  type    = string
  default = "staging"
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
  default = "Standard_B4ms"
}

variable "aks_node_min_count" {
  type    = number
  default = 2
}

variable "aks_node_max_count" {
  type    = number
  default = 5
}

variable "acr_sku" {
  type    = string
  default = "Standard"
}

variable "redis_sku" {
  type    = string
  default = "Standard"
}

variable "redis_capacity" {
  type    = number
  default = 1
}
