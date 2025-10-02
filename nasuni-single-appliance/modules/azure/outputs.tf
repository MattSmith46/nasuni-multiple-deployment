output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.nasuni.name
}

output "vm_name" {
  description = "Name of the VM"
  value       = azurerm_linux_virtual_machine.nasuni.name
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
    vnet_name   = var.existing_vnet_name != "" ? var.existing_vnet_name : azurerm_virtual_network.nasuni[0].name
    subnet_name = var.existing_subnet_name != "" ? var.existing_subnet_name : azurerm_subnet.nasuni[0].name
    nsg_name    = azurerm_network_security_group.nasuni.name
  }
}

output "storage_account_name" {
  description = "Storage account name"
  value       = var.storage_account_name != "" ? var.storage_account_name : azurerm_storage_account.nasuni[0].name
}