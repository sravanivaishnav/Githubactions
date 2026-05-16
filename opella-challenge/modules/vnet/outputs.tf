output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet name to its address prefix."
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes[0] }
}

output "nsg_ids" {
  description = "Map of subnet name to its NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}
