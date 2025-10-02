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