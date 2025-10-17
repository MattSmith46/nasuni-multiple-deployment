output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.nasuni.name
}

output "vm_name" {
  description = "Name of the VM"
  value       = azurerm_linux_virtual_machine.nasuni.name
}

output "vm_id" {
  description = "ID of the VM"
  value       = azurerm_linux_virtual_machine.nasuni.id
}

output "private_ip" {
  description = "Private IP address"
  value       = azurerm_network_interface.nasuni.private_ip_address
}

output "admin_console_url" {
  description = "Nasuni admin console URL (private IP - access via VPN/jump box)"
  value       = "https://${azurerm_network_interface.nasuni.private_ip_address}:8443"
}

output "ssh_command" {
  description = "SSH command to connect to the VM (private IP - access via VPN/jump box)"
  value       = "ssh ${var.admin_username}@${azurerm_network_interface.nasuni.private_ip_address}"
}

output "network_details" {
  description = "Network configuration details"
  value = {
    vnet_name                     = var.existing_vnet_name != "" ? var.existing_vnet_name : (length(azurerm_virtual_network.nasuni) > 0 ? azurerm_virtual_network.nasuni[0].name : "")
    subnet_name                   = var.existing_subnet_name != "" ? var.existing_subnet_name : (length(azurerm_subnet.nasuni) > 0 ? azurerm_subnet.nasuni[0].name : "")
    nsg_name                      = azurerm_network_security_group.nasuni.name
    accelerated_networking_enabled = var.enable_accelerated_networking
  }
}

output "storage_account_name" {
  description = "Storage account name"
  value       = var.storage_account_name != "" ? var.storage_account_name : (length(azurerm_storage_account.nasuni) > 0 ? azurerm_storage_account.nasuni[0].name : "")
}

output "availability_set_id" {
  description = "Availability Set ID"
  value       = local.availability_set_id
}

output "cache_disk_details" {
  description = "Cache disk configuration"
  value = {
    disk_id          = azurerm_managed_disk.cache.id
    disk_size_gb     = var.cache_disk_size_gb
    storage_type     = var.disk_storage_account_type
    iops             = var.disk_storage_account_type == "PremiumV2_LRS" ? var.disk_iops_read_write : null
    throughput_mbps  = var.disk_storage_account_type == "PremiumV2_LRS" ? var.disk_mbps_read_write : null
  }
}

output "dns_reverse_lookup_enabled" {
  description = "Whether DNS reverse lookup is enabled"
  value       = var.enable_dns_reverse_lookup
}

output "dns_reverse_zone_name" {
  description = "DNS reverse lookup zone name"
  value       = var.enable_dns_reverse_lookup ? azurerm_private_dns_zone.reverse_lookup[0].name : ""
}