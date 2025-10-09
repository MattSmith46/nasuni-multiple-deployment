# Nasuni Multi-Appliance Deployment - Workspace Method

Deploy multiple Nasuni Edge Appliances across multiple Azure subscriptions using Terraform workspaces and CSV configuration.

## 🏗️ Architecture Overview

This deployment uses **Terraform workspaces** to isolate deployments per subscription:

- Each workspace deploys to **ONE subscription only**
- Workspaces maintain **separate state files** for isolation
- Deployments are **sequential** (one subscription at a time)
- The CSV file contains **all appliances** across all subscriptions

### Workspace to Subscription Mapping

| Workspace | Subscription | Description |
|-----------|--------------|-------------|
| `pgr` | c7a18a12-... | PGR Subscription |
| `qis` | 6b025554-... | QIS Subscription |
| `qti` | 8f054358-... | QTI Subscription |

## 📋 Prerequisites

1. ✅ Azure CLI authenticated with access to **all** subscriptions
2. ✅ Terraform >= 1.0
3. ✅ Access to the single-appliance Terraform module (included)
4. ✅ Resource Groups and VNets **pre-created** in each subscription
5. ✅ Appropriate RBAC permissions in each subscription
6. ✅ Marketplace terms accepted (automated by deployment scripts)

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone or navigate to the repository
cd nasuni-multiple-deployment

# Authenticate to Azure
az login
az account list --output table

# Copy example files
cp terraform.tfvars.example terraform.tfvars
cp appliances.csv.example appliances.csv

# Edit terraform.tfvars with your credentials
# IMPORTANT: Use environment variables for passwords in production
nano terraform.tfvars

# Edit appliances.csv with your VM configurations
nano appliances.csv
```

### 2. Verify Prerequisites

```bash
# Verify subscription access
./scripts/verify-subscriptions.sh

# Validate CSV format
./scripts/validate-csv.sh

# (Optional) Create resource groups if they don't exist
chmod +x scripts/create-resource-groups.sh
./scripts/create-resource-groups.sh
```

### 3. Deploy to Each Subscription

#### Option A: Deploy All Subscriptions (Automated)

```bash
# Make script executable
chmod +x scripts/deploy-all-subscriptions.sh

# Run automated deployment
./scripts/deploy-all-subscriptions.sh
```

This script will:
1. ✅ Verify access to all subscriptions
2. ✅ Initialize Terraform
3. ✅ Accept marketplace terms in each subscription
4. ✅ Deploy to each workspace sequentially
5. ✅ Prompt for confirmation before each deployment

#### Option B: Deploy Manually Per Workspace

```bash
# Initialize Terraform (first time only)
terraform init

# Deploy to PGR subscription
terraform workspace select pgr
terraform plan
terraform apply

# Deploy to QIS subscription  
terraform workspace select qis
terraform plan
terraform apply

# Deploy to QTI subscription
terraform workspace select qti
terraform plan
terraform apply
```

## 📄 CSV Configuration

### Required Columns (20 total)

Your `appliances.csv` must have exactly 20 columns in this order:

| # | Column | Description | Example |
|---|--------|-------------|---------|
| 1 | vm_name | Unique VM name | PGRSCUTNUNIVP01 |
| 2 | subscription_id | Azure subscription GUID | c7a18a12-7088-... |
| 3 | environment | Environment code | PD, NP, DR |
| 4 | location | Azure region | South Central US |
| 5 | vm_size | Azure VM size | Standard_D8ads_v5 |
| 6 | cache_disk_size_gb | Cache disk size | 1024 |
| 7 | resource_group_name | VM resource group | PGR-Nasuni-pd-scus-rg |
| 8 | network_resource_group_name | Network resource group | PGR-Nasuni-Network-pd-scus-rg |
| 9 | existing_vnet_resource_group | VNet resource group | PGR-Nasuni-Network-pd-scus-rg |
| 10 | existing_vnet_name | VNet name | PGR-Nasuni-Network-pd-scus-vnet |
| 11 | existing_subnet_name | Subnet name | ...vnet-virtualmachine-subnet |
| 12 | storage_account_name | Storage account | pgrscusnasunipdst |
| 13 | enable_virtual_wan | Enable vWAN | false |
| 14 | site | Site identifier | Houston |
| 15 | critical_infrastructure | Yes/No | Yes |
| 16 | external_facing | Yes/No | No |
| 17 | owner | Owner email | user@company.com |
| 18 | project_name | Project name | Nasuni |
| 19 | regulatory_data | Yes/No | Yes |
| 20 | service | Service name | Nasuni |

### CSV Example

```csv
vm_name,subscription_id,environment,location,vm_size,cache_disk_size_gb,resource_group_name,network_resource_group_name,existing_vnet_resource_group,existing_vnet_name,existing_subnet_name,storage_account_name,enable_virtual_wan,site,critical_infrastructure,external_facing,owner,project_name,regulatory_data,service
PGRSCUTNUNIVP01,c7a18a12-7088-4955-8504-5156e8f48fdd,PD,South Central US,Standard_D8ads_v5,1024,PGR-Nasuni-pd-scus-rg,PGR-Nasuni-Network-pd-scus-rg,PGR-Nasuni-Network-pd-scus-rg,PGR-Nasuni-Network-pd-scus-vnet,PGR-Nasuni-Network-pd-scus-vnet-virtualmachine-subnet,pgrscusnasunipdst,false,Houston,Yes,No,cwilliford@quantaservices.com,Nasuni,Yes,Nasuni
```

**Important Notes:**
- ⚠️ All networks must be **pre-existing** (this config doesn't create VNets)
- ⚠️ Resource groups must exist before deployment (or use `create-resource-groups.sh`)
- ⚠️ No public IPs are created (per security policy)

## 🔄 Workspace Management

### View Current Workspace
```bash
terraform workspace show
```

### List All Workspaces
```bash
terraform workspace list
```

### Switch Workspaces
```bash
terraform workspace select pgr
terraform workspace select qis
terraform workspace select qti
```

### Create New Workspace
```bash
# If you add a new subscription
terraform workspace new sub4
```

### View Outputs for Current Workspace
```bash
# See deployed appliances
terraform output nasuni_appliances

# See workspace info
terraform output workspace_info

# See deployment summary
terraform output deployment_summary

# See all subscriptions overview
terraform output all_subscriptions_summary
```

## ➕ Adding More Subscriptions

To add a 4th, 5th, or more subscriptions:

### Step 1: Update `locals.tf`

Add to the `workspace_subscriptions` map:

```hcl
workspace_subscriptions = {
  pgr  = "c7a18a12-7088-4955-8504-5156e8f48fdd"
  qis  = "6b025554-fc3d-49a6-a9a1-56d397909042"
  qti  = "8f054358-9640-4873-a3bf-f1e3547ed39f"
  sub4 = "dddddddd-4444-4444-4444-444444444444"  # New subscription
  sub5 = "eeeeeeee-5555-5555-5555-555555555555"  # Another new one
}
```

### Step 2: Add to CSV

Add rows to `appliances.csv` with the new subscription IDs.

### Step 3: Deploy

```bash
# Create and select new workspace
terraform workspace new sub4
terraform workspace select sub4

# Plan and apply
terraform plan
terraform apply
```

### Step 4: Update Deploy Script (Optional)

Add to `scripts/deploy-all-subscriptions.sh`:

```bash
declare -A WORKSPACES=(
  ["pgr"]="c7a18a12-7088-4955-8504-5156e8f48fdd"
  ["qis"]="6b025554-fc3d-49a6-a9a1-56d397909042"
  ["qti"]="8f054358-9640-4873-a3bf-f1e3547ed39f"
  ["sub4"]="dddddddd-4444-4444-4444-444444444444"  # Add here
)
```

## 🔧 Troubleshooting

### Marketplace Terms Not Accepted

```bash
# Manually accept for a specific subscription
az account set --subscription "<subscription-id>"
az vm image terms accept \
  --publisher nasunicorporation \
  --offer nasuni-nea-90-prod \
  --plan nasuni-nea-9153-prod
```

### Resource Group Not Found

Make sure resource groups exist:

```bash
# Check if resource group exists
az group show --name "RG-NAME" --subscription "<subscription-id>"

# Create if needed
az group create --name "RG-NAME" --location "LOCATION" --subscription "<subscription-id>"
```

### Wrong Subscription

Check which subscription the current workspace uses:

```bash
terraform workspace show
terraform output workspace_info
```

### Appliances Not Showing in Workspace

The workspace filters appliances by subscription. Verify:

1. ✅ You're in the correct workspace: `terraform workspace show`
2. ✅ Your CSV has appliances for that subscription ID
3. ✅ The subscription ID in `locals.tf` matches the CSV

```bash
# Debug: see all appliances across all subscriptions
terraform output all_subscriptions_summary

# See appliances for current workspace only
terraform output nasuni_appliances
```

### No Appliances Found Warning

If you see: `WARNING: No appliances found for workspace...`

This means the current workspace's subscription has no matching VMs in the CSV.

**Fix:**
1. Check `locals.tf` workspace_subscriptions mapping
2. Check CSV has VMs with matching subscription_id
3. Verify you're in the correct workspace

### State Issues After Architecture Change

If you upgraded from an older version with different architecture:

```bash
# List old resources
terraform state list

# Remove old module instances if needed
terraform state rm 'module.nasuni_appliances_pgr'
terraform state rm 'module.nasuni_appliances_qis'
terraform state rm 'module.nasuni_appliances_qti'

# Re-import if needed
terraform import 'module.nasuni_appliances["VM-NAME"].module.azure_nasuni.azurerm_linux_virtual_machine.nasuni' /subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/virtualMachines/VM-NAME
```

## 📁 File Structure

```
nasuni-multiple-deployment/
├── .gitignore                      # Git ignore rules (NEVER commit state or tfvars!)
├── README.md                       # This file
├── main.tf                         # Main Terraform config (single provider with workspace)
├── variables.tf                    # Variable definitions
├── locals.tf                       # Workspace-to-subscription mapping & filtering logic
├── outputs.tf                      # Workspace-specific outputs
├── terraform.tfvars                # Your configuration (DO NOT COMMIT!)
├── terraform.tfvars.example        # Template for terraform.tfvars
├── appliances.csv                  # VM configurations (20 columns)
├── appliances.csv.example          # Template for appliances.csv
├── scripts/
│   ├── deploy-all-subscriptions.sh # Automated deployment to all workspaces
│   ├── verify-subscriptions.sh     # Check access to all subscriptions
│   ├── validate-csv.sh             # Validate CSV format
│   └── create-resource-groups.sh   # Create resource groups from CSV
└── nasuni-single-appliance/        # Single appliance module
    ├── main.tf
    ├── variables.tf
    ├── locals.tf
    ├── outputs.tf
    └── modules/azure/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔐 Security Best Practices

### 1. Password Management

**❌ BAD** (current):
```hcl
admin_password = "!!!HPVmw@r3!!!"
```

**✅ GOOD** (recommended):
```bash
# Use environment variables
export TF_VAR_admin_username="qadmin"
export TF_VAR_admin_password="YourSecurePassword123!"

# Then remove from terraform.tfvars
```

**✅ BEST** (production):
- Use Azure Key Vault to store passwords
- Reference Key Vault secrets in Terraform
- Rotate passwords regularly

### 2. Network Security

Current NSG rules have been updated to use `VirtualNetwork` instead of `*`:

```hcl
source_address_prefix = "VirtualNetwork"  # Only allow VNet traffic
```

**Further hardening options:**
- Use specific IP ranges: `10.0.0.0/8`
- Use Azure Firewall for centralized control
- Implement Network Security Groups per subnet
- Use Azure Private Link for storage accounts

### 3. State File Security

**CRITICAL:** Never commit state files!

```bash
# Already in .gitignore, but verify:
*.tfstate
*.tfstate.*
*.tfstate.backup
```

**Recommended:** Use remote state storage

```hcl
# Add to main.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<uniqueid>"
    container_name       = "tfstate"
    key                  = "nasuni.tfstate"
  }
}
```

### 4. Least Privilege

Ensure service principals/users have only necessary permissions:
- `Virtual Machine Contributor` for VM operations
- `Network Contributor` for network operations
- `Storage Account Contributor` for storage operations

### 5. Audit Logging

Enable Azure Activity Logs and diagnostic settings for all resources.

## 📊 Outputs Reference

### `nasuni_appliances`
Details of deployed appliances in the current workspace:
```json
{
  "VM-NAME": {
    "subscription_id": "...",
    "workspace": "pgr",
    "vm_name": "...",
    "private_ip": "...",
    "admin_console_url": "https://...:8443",
    "ssh_command": "ssh user@...",
    "network_details": {...},
    "storage_account_name": "..."
  }
}
```

### `workspace_info`
Current workspace information:
```json
{
  "workspace": "pgr",
  "subscription_id": "c7a18a12-...",
  "appliance_count": 1
}
```

### `deployment_summary`
Summary of current workspace deployment:
```json
{
  "workspace": "pgr",
  "subscription_id": "c7a18a12-...",
  "appliance_names": ["VM1", "VM2"],
  "total_cache_size_gb": 2048,
  "locations": ["South Central US"]
}
```

### `all_subscriptions_summary`
Overview of all appliances across all subscriptions (from CSV):
```json
{
  "total_subscriptions": 3,
  "subscriptions": ["c7a18a12-...", "6b025554-...", "8f054358-..."],
  "appliances_by_sub": {
    "c7a18a12-...": ["VM1", "VM2"],
    "6b025554-...": ["VM3"]
  },
  "total_appliances": 3
}
```

## 🎯 Common Workflows

### Deploy New Appliance to Existing Subscription

1. Add row to `appliances.csv`
2. Select workspace: `terraform workspace select <workspace>`
3. Plan: `terraform plan`
4. Apply: `terraform apply`

### Deploy to New Subscription

1. Update `locals.tf` with new subscription
2. Add rows to `appliances.csv`
3. Create workspace: `terraform workspace new <name>`
4. Deploy: `terraform apply`

### Update Existing Appliance

1. Modify row in `appliances.csv`
2. Select workspace: `terraform workspace select <workspace>`
3. Plan: `terraform plan` (verify changes)
4. Apply: `terraform apply`

### Destroy Appliance

```bash
# Select workspace
terraform workspace select <workspace>

# Destroy specific appliance
terraform destroy -target='module.nasuni_appliances["VM-NAME"]'

# Or destroy all in workspace
terraform destroy
```

### Check Deployment Status

```bash
# Current workspace
terraform workspace show
terraform output deployment_summary

# All workspaces
for ws in pgr qis qti; do
  echo "=== Workspace: $ws ==="
  terraform workspace select $ws
  terraform output deployment_summary 2>/dev/null || echo "No deployment"
done
```

## 📞 Support

For issues:
- **Terraform errors**: Check this README and Terraform documentation
- **Azure permissions**: Contact your Azure administrator
- **Nasuni appliance**: Contact Nasuni support
- **Network connectivity**: Verify NSG rules and VNet configuration

## 📝 Changelog

### v2.0 (Current)
- ✅ Fixed: Removed unused `subscription_aliases` variable
- ✅ Fixed: Updated NSG rules to use `VirtualNetwork` instead of `*`
- ✅ Fixed: Implemented `create-resource-groups.sh` script
- ✅ Added: Workspace validation and warnings
- ✅ Added: Example configuration files
- ✅ Security: Enhanced password management documentation
- ✅ Docs: Clarified workspace-based deployment approach

### v1.0
- Initial workspace-based multi-subscription deployment

## 📜 License

[Your License Here]

---

**Important Reminders:**
- 🔒 Never commit `terraform.tfvars` or state files
- 🔐 Use environment variables for passwords in production
- 🔄 Always run `terraform plan` before `apply`
- 📋 Keep your CSV file updated and validated
- 🧪 Test in non-production first