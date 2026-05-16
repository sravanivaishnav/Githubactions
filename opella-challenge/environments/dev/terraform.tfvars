# Dev environment Ã¢â‚¬â€ eastus, LRS storage, Standard_B1s VM
subscription_id    = "559863b0-673d-4bbb-a4d7-2be41aa0c07c"
project_name       = "opella"
location           = "eastus"
vnet_address_space = ["10.10.0.0/16"]
subnet_web_prefix  = "10.10.1.0/24"
subnet_app_prefix  = "10.10.2.0/24"
vm_size            = "Standard_B1s"
vm_admin_username  = "azureuser"

# vm_public_key is intentionally omitted Ã¢â‚¬â€ generated in CI by the workflow

tags = {
  Owner      = "letsmovemom@gmail.com"
  CostCenter = "opella-challenge"
}