# Dev environment — eastus, LRS storage, Standard_B1s VM
subscription_id    = "54f5d471-6e4f-485a-ab96-4d64c131393b"
project_name       = "opella"
location           = "eastus"
vnet_address_space = ["10.10.0.0/16"]
subnet_web_prefix  = "10.10.1.0/24"
subnet_app_prefix  = "10.10.2.0/24"
vm_size            = "Standard_B1s"
vm_admin_username  = "azureuser"

# vm_public_key is intentionally omitted here — set via:
#   export TF_VAR_vm_public_key="$(cat ~/.ssh/id_rsa.pub)"
# or as a GitHub Actions secret (TF_VAR_VM_PUBLIC_KEY)

tags = {
  Owner      = "sravani.vangara@accenture.com"
  CostCenter = "opella-challenge"
}
