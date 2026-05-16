variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group where the VNet will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the VNet (e.g., eastus, westeurope)."
  type        = string
}

variable "address_space" {
  description = "List of CIDR blocks for the VNet address space."
  type        = list(string)
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. Each key is the subnet name; value is an object with:
      - address_prefix    : CIDR block for the subnet.
      - service_endpoints : List of Azure service endpoints (e.g., ["Microsoft.Storage"]).
      - nsg_rules         : Optional list of NSG rules; defaults to deny-all if omitted.
  EOT
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
}

variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Network Protection plan on the VNet. Note: this incurs additional cost."
  type        = bool
  default     = false
}

variable "dns_servers" {
  description = "List of custom DNS server IP addresses. Leave empty to use Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
