# Production environment â€” westeurope, GRS storage, Standard_B2s VM
subscription_id    = "559863b0-673d-4bbb-a4d7-2be41aa0c07c"
project_name       = "opella"
location           = "westeurope"
vnet_address_space = ["10.20.0.0/16"]
subnet_web_prefix  = "10.20.1.0/24"
subnet_app_prefix  = "10.20.2.0/24"
vm_size            = "Standard_B2s"
vm_admin_username  = "azureuser"

# vm_public_key is intentionally omitted â€” generated in CI by the workflow

tags = {
  Owner      = "letsmovemom@gmail.com"
  CostCenter = "opella-challenge"
}

