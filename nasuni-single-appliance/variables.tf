# Common Variables
variable "vm_name" {
  description = "Name of the Nasuni appliance VM"
  type        = string
  default     = "nasuni-nea"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "South Central US"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "cache_disk_size_gb" {
  description = "Size of cache disk in GB"
  type        = number
  default     = 128
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "network_cidr" {
  description = "CIDR block for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    "application" = "nasuni"
    "environment" = "dev"
  }
}

# Azure-specific variables
variable "azure_config" {
  description = "Azure-specific configuration"
  type = object({
    subscription_id               = string
    resource_group_name          = string
    existing_vnet_resource_group = optional(string, "")
    existing_vnet_name          = optional(string, "")
    existing_subnet_name        = optional(string, "")
    storage_account_name        = optional(string, "")
    enable_virtual_wan          = optional(bool, false)
  })
}

# New variables for requirements
variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on the NIC"
  type        = bool
  default     = true
}

variable "disk_storage_account_type" {
  description = "Storage account type for cache disk (Premium_LRS, PremiumV2_LRS)"
  type        = string
  default     = "PremiumV2_LRS"
}

variable "disk_iops_read_write" {
  description = "IOPS for PremiumV2_LRS disks"
  type        = number
  default     = 3000
}

variable "disk_mbps_read_write" {
  description = "Throughput (MB/s) for PremiumV2_LRS disks"
  type        = number
  default     = 125
}

variable "enable_dns_reverse_lookup" {
  description = "Enable DNS reverse lookup configuration"
  type        = bool
  default     = false
}

variable "dns_servers" {
  description = "List of DNS servers for the VNet"
  type        = list(string)
  default     = []
}

variable "custom_nsg_rules" {
  description = "Additional custom NSG rules to apply"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "availability_set_id" {
  description = "ID of existing availability set (optional)"
  type        = string
  default     = null
}