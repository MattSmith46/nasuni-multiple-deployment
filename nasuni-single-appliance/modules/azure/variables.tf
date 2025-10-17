# Common variables
variable "vm_name" {
  description = "Name of the Nasuni appliance VM"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "cache_disk_size_gb" {
  description = "Cache disk size in GB"
  type        = number
}

variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "network_cidr" {
  description = "Network CIDR"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
}

variable "security_rules" {
  description = "Security rules"
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
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# Azure-specific variables
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "existing_vnet_resource_group" {
  description = "Existing VNet resource group"
  type        = string
  default     = ""
}

variable "existing_vnet_name" {
  description = "Existing VNet name"
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "Existing subnet name"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
  default     = ""
}

variable "enable_virtual_wan" {
  description = "Enable Virtual WAN integration"
  type        = bool
  default     = false
}

# New variables for requirements
variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on the NIC"
  type        = bool
  default     = true
}

variable "availability_set_id" {
  description = "ID of the availability set to join (optional)"
  type        = string
  default     = null
}

variable "disk_storage_account_type" {
  description = "Storage account type for cache disk (Premium_LRS, PremiumV2_LRS)"
  type        = string
  default     = "PremiumV2_LRS"
  
  validation {
    condition     = contains(["Premium_LRS", "PremiumV2_LRS", "StandardSSD_LRS"], var.disk_storage_account_type)
    error_message = "Disk storage account type must be Premium_LRS, PremiumV2_LRS, or StandardSSD_LRS."
  }
}

variable "disk_iops_read_write" {
  description = "IOPS for PremiumV2_LRS disks (3000-160000)"
  type        = number
  default     = 3000
  
  validation {
    condition     = var.disk_iops_read_write >= 3000 && var.disk_iops_read_write <= 160000
    error_message = "IOPS must be between 3000 and 160000 for PremiumV2_LRS disks."
  }
}

variable "disk_mbps_read_write" {
  description = "Throughput (MB/s) for PremiumV2_LRS disks (125-10000)"
  type        = number
  default     = 125
  
  validation {
    condition     = var.disk_mbps_read_write >= 125 && var.disk_mbps_read_write <= 10000
    error_message = "Throughput must be between 125 and 10000 MB/s for PremiumV2_LRS disks."
  }
}

variable "enable_dns_reverse_lookup" {
  description = "Enable DNS reverse lookup configuration"
  type        = bool
  default     = false
}

variable "dns_servers" {
  description = "List of DNS servers for the VNet (for reverse lookup)"
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