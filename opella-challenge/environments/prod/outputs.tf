output "resource_group_name" {
  description = "Name of the prod resource group."
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Resource ID of the prod VNet."
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "Name of the prod VNet."
  value       = module.vnet.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet name to resource ID."
  value       = module.vnet.subnet_ids
}

output "storage_account_name" {
  description = "Name of the storage account (randomised suffix)."
  value       = azurerm_storage_account.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the prod VM."
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_name" {
  description = "Name of the Linux VM."
  value       = azurerm_linux_virtual_machine.main.name
}
