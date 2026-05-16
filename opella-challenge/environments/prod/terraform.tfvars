subscription_id    = "54f5d471-6e4f-485a-ab96-4d64c131393b"
project_name       = "opella"
location           = "westeurope"
vnet_address_space = ["10.20.0.0/16"]
subnet_web_prefix  = "10.20.1.0/24"
subnet_app_prefix  = "10.20.2.0/24"
vm_size            = "Standard_B2s"
vm_admin_username  = "azureuser"

# vm_public_key is intentionally omitted — set via GitHub secret (TF_VAR_VM_PUBLIC_KEY)

tags = {
  Owner      = "sravani.vangara@accenture.com"
  CostCenter = "opella-challenge"
}
