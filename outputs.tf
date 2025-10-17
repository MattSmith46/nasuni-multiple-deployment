output "nasuni_appliances" {
  description = "Details of deployed Nasuni appliances in current workspace"
  value = {
    for k, v in module.nasuni_appliances : k => {
      subscription_id               = local.current_subscription_id
      workspace                     = local.current_workspace
      resource_group_name           = v.azure_nasuni.resource_group_name
      vm_name                       = v.azure_nasuni.vm_name
      vm_id                         = v.azure_nasuni.vm_id
      private_ip                    = v.azure_nasuni.private_ip
      admin_console_url             = v.azure_nasuni.admin_console_url
      ssh_command                   = v.azure_nasuni.ssh_command
      network_details               = v.azure_nasuni.network_details
      storage_account_name          = v.azure_nasuni.storage_account_name
      availability_set_id           = v.azure_nasuni.availability_set_id
      cache_disk_details            = v.azure_nasuni.cache_disk_details
      dns_reverse_lookup_enabled    = v.azure_nasuni.dns_reverse_lookup_enabled
      dns_reverse_zone_name         = v.azure_nasuni.dns_reverse_zone_name
    }
  }
}

output "workspace_info" {
  description = "Current workspace information"
  value = {
    workspace       = local.current_workspace
    subscription_id = local.current_subscription_id
    appliance_count = length(local.filtered_appliances)
  }
}

output "deployment_summary" {
  description = "Summary of deployment in current workspace"
  value = {
    workspace            = local.current_workspace
    subscription_id      = local.current_subscription_id
    appliance_names      = [for k, v in module.nasuni_appliances : v.azure_nasuni.vm_name]
    total_cache_size_gb  = sum([for a in local.filtered_appliances : tonumber(a.cache_disk_size_gb)])
    locations           = distinct([for a in local.filtered_appliances : a.location])
    accelerated_networking = distinct([for a in local.filtered_appliances : a.accelerated_networking])
    disk_types          = distinct([for a in local.filtered_appliances : a.disk_type])
  }
}

output "all_subscriptions_summary" {
  description = "Summary of all appliances across all subscriptions (from CSV)"
  value = {
    total_subscriptions = length(local.unique_subscriptions)
    subscriptions       = local.unique_subscriptions
    appliances_by_sub   = local.appliances_by_subscription
    total_appliances    = length(local.all_appliances)
  }
}