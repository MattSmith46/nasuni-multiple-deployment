terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# REMOVED: provider "azurerm" block - providers are passed from parent module

# Azure Deployment
module "azure_nasuni" {
  source = "./modules/azure"
  
  # Common variables
  vm_name            = var.vm_name
  environment        = var.environment
  location          = var.location
  vm_size           = var.vm_size
  cache_disk_size_gb = var.cache_disk_size_gb
  admin_username    = var.admin_username
  admin_password    = var.admin_password
  network_cidr      = var.network_cidr
  subnet_cidr       = var.subnet_cidr
  security_rules    = local.security_rules
  tags              = var.tags
  
  # Azure-specific variables
  subscription_id               = var.azure_config.subscription_id
  resource_group_name          = var.azure_config.resource_group_name
  existing_vnet_resource_group = var.azure_config.existing_vnet_resource_group
  existing_vnet_name          = var.azure_config.existing_vnet_name
  existing_subnet_name        = var.azure_config.existing_subnet_name
  storage_account_name        = var.azure_config.storage_account_name
  enable_virtual_wan          = var.azure_config.enable_virtual_wan
  
  # New configuration options
  enable_accelerated_networking = var.enable_accelerated_networking
  disk_storage_account_type     = var.disk_storage_account_type
  disk_iops_read_write          = var.disk_iops_read_write
  disk_mbps_read_write          = var.disk_mbps_read_write
  enable_dns_reverse_lookup     = var.enable_dns_reverse_lookup
  dns_servers                   = var.dns_servers
  custom_nsg_rules              = var.custom_nsg_rules
  availability_set_id           = var.availability_set_id
  
  name_prefix = local.name_prefix
}