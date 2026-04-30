output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}

output "acr_name" {
  value = module.acr.acr_name
}

output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "cosmosdb_account_name" {
  value = module.cosmosdb.cosmosdb_account_name
}

output "redis_hostname" {
  value = module.redis.redis_hostname
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "log_analytics_workspace_name" {
  value = module.monitoring.log_analytics_workspace_name
}
