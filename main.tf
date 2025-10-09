terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Single provider - subscription determined by workspace
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = local.current_subscription_id
}

# Output warning if no appliances found for current workspace
resource "null_resource" "workspace_validation" {
  triggers = {
    workspace = local.current_workspace
    warning   = local.workspace_warning
  }

  provisioner "local-exec" {
    command = local.has_appliances ? "echo 'Workspace ${local.current_workspace}: Found ${length(local.filtered_appliances)} appliance(s)'" : "echo '${local.workspace_warning}'"
  }
}

# Automatically accept marketplace terms for current subscription
resource "null_resource" "accept_marketplace_terms" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Accepting marketplace terms for subscription ${local.current_subscription_id}..."
      az account set --subscription "${local.current_subscription_id}"
      az vm image terms accept \
        --publisher nasunicorporation \
        --offer nasuni-nea-90-prod \
        --plan nasuni-nea-9153-prod \
        --output none || echo "Terms may already be accepted or you may not have permissions"
    EOT
  }

  triggers = {
    subscription_id = local.current_subscription_id
  }
}

# Deploy appliances for current workspace's subscription only
module "nasuni_appliances" {
  source   = "./nasuni-single-appliance"
  for_each = { for a in local.filtered_appliances : a.vm_name => a }

  depends_on = [
    null_resource.accept_marketplace_terms,
    null_resource.workspace_validation
  ]

  vm_name            = each.value.vm_name
  environment        = each.value.environment
  location           = each.value.location
  vm_size            = each.value.vm_size
  cache_disk_size_gb = tonumber(each.value.cache_disk_size_gb)
  admin_username     = var.admin_username
  admin_password     = var.admin_password
  network_cidr       = ""  # Not used - always using existing networks
  subnet_cidr        = ""  # Not used - always using existing networks
  tags               = {
    critical-infrastructure = each.value.critical_infrastructure
    environment            = each.value.environment
    external-facing        = each.value.external_facing
    owner                  = each.value.owner
    project-name           = each.value.project_name
    regulatory-data        = each.value.regulatory_data
    Service                = each.value.service
  }

  azure_config = {
    subscription_id               = each.value.subscription_id
    resource_group_name          = each.value.resource_group_name
    existing_vnet_resource_group = each.value.existing_vnet_resource_group != "" ? each.value.existing_vnet_resource_group : each.value.network_resource_group_name
    existing_vnet_name           = each.value.existing_vnet_name
    existing_subnet_name         = each.value.existing_subnet_name
    storage_account_name         = each.value.storage_account_name != "" ? each.value.storage_account_name : null
    enable_virtual_wan           = each.value.enable_virtual_wan == "true" ? true : false
  }
}