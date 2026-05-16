# Azure VNET Module

Provisions an Azure Virtual Network with configurable subnets, NSGs, service endpoints, and optional DDoS protection.

> **Auto-generated documentation**: Run `terraform-docs markdown . > README.md` inside this directory to regenerate this file from source.

## Features

- One or many subnets via a single `subnets` map variable
- Per-subnet Network Security Group with configurable rules
- Optional Azure DDoS Network Protection plan
- Custom DNS server support
- Service endpoint support per subnet
- Consistent tagging across all resources

## Usage

```hcl
module "vnet" {
  source = "../../modules/vnet"

  vnet_name           = "vnet-myapp-dev-eastus"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  address_space       = ["10.10.0.0/16"]

  subnets = {
    "snet-web" = {
      address_prefix    = "10.10.1.0/24"
      service_endpoints = ["Microsoft.Storage"]
      nsg_rules = [
        {
          name                       = "allow-https-inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        }
      ]
    }
    "snet-app" = {
      address_prefix    = "10.10.2.0/24"
      service_endpoints = []
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vnet_name` | Name of the Virtual Network | `string` | — | yes |
| `resource_group_name` | Resource Group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `address_space` | CIDR blocks for the VNet | `list(string)` | — | yes |
| `subnets` | Map of subnet configs | `map(object)` | — | yes |
| `enable_ddos_protection` | Enable DDoS Network Protection | `bool` | `false` | no |
| `dns_servers` | Custom DNS servers | `list(string)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Resource ID of the VNet |
| `vnet_name` | Name of the VNet |
| `vnet_address_space` | Address space list |
| `subnet_ids` | Map of subnet name → subnet ID |
| `subnet_address_prefixes` | Map of subnet name → CIDR |
| `nsg_ids` | Map of subnet name → NSG ID |

## Design Decisions

**Why an NSG per subnet (not per NIC)?** Subnet-level NSGs enforce a security boundary at the network layer, applying to all traffic regardless of VM configuration — this follows Azure's defence-in-depth model.

**Why `optional()` for nsg_rules?** Callers that don't need custom rules get a clean interface; the NSG is still created (providing a deny-all baseline for any future rules) without forcing boilerplate on every subnet.

**Why expose `subnet_ids` as a map?** Downstream resources (VMs, private endpoints) reference subnets by name, not index — a map output avoids brittle positional references that break when subnets are added or removed.
