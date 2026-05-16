terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  required_version = ">= 1.5.0"

  # Uncomment after creating a storage account for remote state:
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "stterraformstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "prod.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  env    = "prod"
  region = var.location

  tags = merge(var.tags, {
    Environment = local.env
    Region      = local.region
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })
}

# ── Resource Group ─────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${local.env}-${local.region}"
  location = local.region
  tags     = local.tags
}

# ── Virtual Network (reusable module) ─────────────────────────────────────────
module "vnet" {
  source = "../../modules/vnet"

  vnet_name           = "vnet-${var.project_name}-${local.env}-${local.region}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = var.vnet_address_space
  tags                = local.tags

  # Prod uses a separate, non-overlapping address space (10.20.0.0/16)
  subnets = {
    "snet-web-${local.env}" = {
      address_prefix    = var.subnet_web_prefix
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
        },
        {
          name                       = "deny-http-inbound"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        }
      ]
    }
    "snet-app-${local.env}" = {
      address_prefix    = var.subnet_app_prefix
      service_endpoints = []
      nsg_rules = [
        {
          name                       = "allow-web-to-app"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = var.subnet_web_prefix
          destination_address_prefix = "*"
        }
      ]
    }
  }
}

# ── Storage Account + Blob Container ──────────────────────────────────────────
resource "random_id" "storage_suffix" {
  byte_length = 3
}

resource "azurerm_storage_account" "main" {
  name                     = "st${var.project_name}${local.env}${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-web-${local.env}"]]
  }

  tags = local.tags
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# ── Virtual Machine ────────────────────────────────────────────────────────────
resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${var.project_name}-${local.env}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${var.project_name}-${local.env}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.subnet_ids["snet-web-${local.env}"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "vm-${var.project_name}-${local.env}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  tags                            = local.tags

  network_interface_ids = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_public_key
  }

  os_disk {
    name                 = "osdisk-vm-${var.project_name}-${local.env}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
