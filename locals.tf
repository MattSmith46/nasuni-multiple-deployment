locals {
  # Load and parse the CSV file
  appliances_raw = csvdecode(file(var.appliances_csv_path))
  
  # Process all appliances (validate and set defaults)
  all_appliances = [
    for a in local.appliances_raw : {
      vm_name                      = a.vm_name
      subscription_id              = a.subscription_id
      environment                  = a.environment
      location                     = a.location
      vm_size                      = a.vm_size
      cache_disk_size_gb          = a.cache_disk_size_gb
      resource_group_name         = a.resource_group_name
      network_resource_group_name = try(a.network_resource_group_name, a.resource_group_name)
      existing_vnet_resource_group = try(a.existing_vnet_resource_group, "")
      existing_vnet_name          = try(a.existing_vnet_name, "")
      existing_subnet_name        = try(a.existing_subnet_name, "")
      storage_account_name        = try(a.storage_account_name, "")
      enable_virtual_wan          = try(a.enable_virtual_wan, "false")
      site                        = try(a.site, "")
      # Tags from CSV
      critical_infrastructure     = try(a.critical_infrastructure, "Yes")
      external_facing            = try(a.external_facing, "No")
      owner                      = try(a.owner, "")
      project_name               = try(a.project_name, "Nasuni")
      regulatory_data            = try(a.regulatory_data, "Yes")
      service                    = try(a.service, "Nasuni")
    }
  ]

  # Workspace to subscription mapping
  workspace_subscriptions = {
    pgr = "c7a18a12-7088-4955-8504-5156e8f48fdd"
    qis = "6b025554-fc3d-49a6-a9a1-56d397909042"
    qti = "8f054358-9640-4873-a3bf-f1e3547ed39f"
    # Add more subscriptions here as needed:
    # sub4 = "dddddddd-4444-4444-4444-444444444444"
    # sub5 = "eeeeeeee-5555-5555-5555-555555555555"
  }

  # Get current workspace (defaults to "default" if no workspace selected)
  current_workspace = terraform.workspace

  # Get subscription ID for current workspace
  current_subscription_id = lookup(
    local.workspace_subscriptions,
    local.current_workspace,
    var.default_subscription_id  # Fallback to default for "default" workspace
  )

  # Filter appliances for current subscription only
  filtered_appliances = [
    for a in local.all_appliances : a
    if a.subscription_id == local.current_subscription_id
  ]

  # Extract unique subscription IDs for validation
  unique_subscriptions = distinct([for a in local.all_appliances : a.subscription_id])
  
  # Group all appliances by subscription for reporting
  appliances_by_subscription = {
    for sub in local.unique_subscriptions : sub => [
      for a in local.all_appliances : a.vm_name if a.subscription_id == sub
    ]
  }
}