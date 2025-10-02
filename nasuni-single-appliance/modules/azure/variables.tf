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