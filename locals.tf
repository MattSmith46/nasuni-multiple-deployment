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
      
      # New optional fields with defaults
      accelerated_networking      = try(a.accelerated_networking, "true")
      disk_type                   = try(a.disk_type, "Premium_LRS")
      disk_iops                   = try(a.disk_iops, "3000")
      disk_mbps                   = try(a.disk_mbps, "125")
      enable_dns_reverse          = try(a.enable_dns_reverse, "false")
      dns_servers                 = try(a.dns_servers, "")
      availability_set_name       = try(a.availability_set_name, "")
      
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
  # Add more subscriptions here as needed
  # The workspace name is used with: terraform workspace select <name>
  workspace_subscriptions = {
    pgr = "c7a18a12-7088-4955-8504-5156e8f48fdd"
    qis = "6b025554-fc3d-49a6-a9a1-56d397909042"
    qti = "8f054358-9640-4873-a3bf-f1e3547ed39f"
    nlc = "c6acb9eb-b6f5-4d21-8794-8585174f9a49"
    ugc = "6924ee6e-7efc-40b2-a432-fd4056ff11ed"
    qco = "bc1f6e12-bffe-4aa1-84e0-4c3cd6e3a8d4"
    ims = "debd8577-362f-4c5f-aafa-d2075a7113fc"
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
  # This ensures each workspace only deploys to its assigned subscription
  filtered_appliances = [
    for a in local.all_appliances : a
    if a.subscription_id == local.current_subscription_id
  ]

  # Extract unique subscription IDs for validation and reporting
  unique_subscriptions = distinct([for a in local.all_appliances : a.subscription_id])
  
  # Group all appliances by subscription for reporting
  appliances_by_subscription = {
    for sub in local.unique_subscriptions : sub => [
      for a in local.all_appliances : a.vm_name if a.subscription_id == sub
    ]
  }
  
  # Validation: Check if current workspace has any appliances
  has_appliances = length(local.filtered_appliances) > 0
  
  # Warning message if no appliances found for current workspace
  workspace_warning = local.has_appliances ? "" : "WARNING: No appliances found for workspace '${local.current_workspace}' with subscription '${local.current_subscription_id}'. Check your CSV file and workspace mapping."
}