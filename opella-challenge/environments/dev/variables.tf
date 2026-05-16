variable "subscription_id" {
  description = "Azure Subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID."
  type        = string
  default     = "45ea4c00-dbf3-482e-96b9-6db48b1ae68e"
}

variable "project_name" {
  description = "Short project identifier used in resource names (lowercase, no spaces)."
  type        = string
  default     = "opella"
}

variable "location" {
  description = "Azure region for dev resources."
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "Address space for the dev VNet."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_web_prefix" {
  description = "CIDR for the web subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "subnet_app_prefix" {
  description = "CIDR for the app subnet."
  type        = string
  default     = "10.10.2.0/24"
}

variable "vm_size" {
  description = "Size of the Linux VM (Standard_B1s is free-tier eligible)."
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "vm_public_key" {
  description = "SSH public key for VM admin access. Set via TF_VAR_vm_public_key or GitHub secret."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Additional tags merged with the default tag set."
  type        = map(string)
  default     = {}
}
