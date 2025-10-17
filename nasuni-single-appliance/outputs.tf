output "azure_nasuni" {
  description = "Azure Nasuni deployment outputs"
  value = {
    resource_group_name           = module.azure_nasuni.resource_group_name
    vm_name                       = module.azure_nasuni.vm_name
    vm_id                         = module.azure_nasuni.vm_id
    private_ip                    = module.azure_nasuni.private_ip
    admin_console_url             = module.azure_nasuni.admin_console_url
    ssh_command                   = module.azure_nasuni.ssh_command
    network_details               = module.azure_nasuni.network_details
    storage_account_name          = module.azure_nasuni.storage_account_name
    availability_set_id           = module.azure_nasuni.availability_set_id
    cache_disk_details            = module.azure_nasuni.cache_disk_details
    dns_reverse_lookup_enabled    = module.azure_nasuni.dns_reverse_lookup_enabled
    dns_reverse_zone_name         = module.azure_nasuni.dns_reverse_zone_name
  }
}