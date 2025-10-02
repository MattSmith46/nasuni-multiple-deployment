output "nasuni_appliances" {
  description = "Details of deployed Nasuni appliances in current workspace"
  value = {
    for k, v in module.nasuni_appliances : k => {
      subscription_id      = local.current_subscription_id
      workspace           = local.current_workspace
      resource_group_name = v.azure_nasuni.resource_group_name
      vm_name             = v.azure_nasuni.vm_name
      private_ip          = v.azure_nasuni.private_ip
      admin_console_url   = v.azure_nasuni.admin_console_url
      ssh_command         = v.azure_nasuni.ssh_command
      network_details     = v.azure_nasuni.network_details
      storage_account_name = v.azure_nasuni.storage_account_name
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