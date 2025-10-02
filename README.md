# Nasuni Multi-Appliance Deployment - Workspace Method

Deploy multiple Nasuni Edge Appliances across multiple Azure subscriptions using Terraform workspaces and CSV configuration.

## How It Works

This approach uses **Terraform workspaces** to deploy to multiple subscriptions. Each workspace represents one subscription:

- `pgr` workspace → PGR subscription
- `qis` workspace → QIS subscription  
- `qti` workspace → QTI subscription

## Prerequisites

1. Azure CLI authenticated with access to ALL subscriptions
2. Terraform >= 1.0
3. Access to the single-appliance Terraform module
4. Resource Groups and VNets pre-created in each subscription
5. Appropriate permissions in each subscription

## Quick Start

### 1. Setup

```bash
# Authenticate to Azure
az login
az account list --output table

# Verify access to all subscriptions
./scripts/verify-subscriptions.sh
```

### 2. Configure

Edit `appliances.csv` with your VM configurations. The CSV should have 20 columns (network_cidr and subnet_cidr removed):

```csv
vm_name,subscription_id,environment,location,vm_size,cache_disk_size_gb,resource_group_name,network_resource_group_name,existing_vnet_resource_group,existing_vnet_name,existing_subnet_name,storage_account_name,enable_virtual_wan,site,critical_infrastructure,external_facing,owner,project_name,regulatory_data,service
```

### 3. Deploy to Each Subscription

**Option A: Deploy All (Automated)**
```bash
chmod +x scripts/deploy-all-subscriptions.sh
./scripts/deploy-all-subscriptions.sh
```

**Option B: Deploy Manually Per Workspace**
```bash
# Initialize
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

## CSV Configuration

### Required Columns (20 total)

| Column | Description | Example |
|--------|-------------|---------|
| vm_name | Unique VM name | PGRSCUTNUNIVP01 |
| subscription_id | Azure subscription GUID | c7a18a12-... |
| environment | Environment (PD/NP/DR) | PD |
| location | Azure region | South Central US |
| vm_size | Azure VM size | Standard_D8ads_v5 |
| cache_disk_size_gb | Cache disk size | 1024 |
| resource_group_name | VM resource group | PGR-Nasuni-pd-scus-rg |
| network_resource_group_name | Network resource group | PGR-Nasuni-Network-pd-scus-rg |
| existing_vnet_resource_group | VNet resource group | PGR-Nasuni-Network-pd-scus-rg |
| existing_vnet_name | Existing VNet name | PGR-Nasuni-Network-pd-scus-vnet |
| existing_subnet_name | Existing subnet name | ...vnet-virtualmachine-subnet |
| storage_account_name | Storage account | pgrscusnasunipdst |
| enable_virtual_wan | Enable vWAN (true/false) | false |
| site | Site identifier | Houston |
| critical_infrastructure | Yes/No | Yes |
| external_facing | Yes/No | No |
| owner | Owner email | cwilliford@quantaservices.com |
| project_name | Project name | Nasuni |
| regulatory_data | Yes/No | Yes |
| service | Service name | Nasuni |

**Note:** `network_cidr` and `subnet_cidr` columns have been removed since all networks are pre-existing.

## Workspace Management

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

### View Outputs for Current Workspace
```bash
terraform output nasuni_appliances
terraform output workspace_info
terraform output deployment_summary
```

## Adding More Subscriptions

To add a 4th, 5th, or more subscriptions:

1. **Update `locals.tf`** - Add to `workspace_subscriptions` map:
```hcl
workspace_subscriptions = {
  pgr = "c7a18a12-7088-4955-8504-5156e8f48fdd"
  qis = "6b025554-fc3d-49a6-a9a1-56d397909042"
  qti = "8f054358-9640-4873-a3bf-f1e3547ed39f"
  sub4 = "dddddddd-4444-4444-4444-444444444444"  # Add new subscription
  sub5 = "eeeeeeee-5555-5555-5555-555555555555"  # Add another
}
```

2. **Add rows to `appliances.csv`** with the new subscription IDs

3. **Create new workspace and deploy**:
```bash
terraform workspace new sub4
terraform workspace select sub4
terraform apply
```

That's it! No provider blocks or module blocks to add.

## Troubleshooting

### Marketplace Terms Not Accepted
```bash
az account set --subscription "<subscription-id>"
az vm image terms accept \
  --publisher nasunicorporation \
  --offer nasuni-nea-90-prod \
  --plan nasuni-nea-9153-prod
```

### Resource Group Not Found
Make sure resource groups exist before deploying:
```bash
az group create --name "RG-NAME" --location "LOCATION"
```

### Wrong Subscription
Check which subscription the current workspace uses:
```bash
terraform workspace show
terraform output workspace_info
```

### Appliances Not Showing
The workspace filters appliances by subscription. Make sure:
1. You're in the correct workspace
2. Your CSV has appliances for that subscription ID
3. The subscription ID in `locals.tf` matches the CSV

## File Structure

```
nasuni-multiple-deployment/
├── main.tf                    # Single provider, workspace-based
├── variables.tf               # Variable definitions
├── locals.tf                  # Workspace-to-subscription mapping
├── outputs.tf                 # Workspace-specific outputs
├── terraform.tfvars           # Your configuration
├── appliances.csv             # VM configurations (20 columns)
├── README.md                  # This file
├── scripts/
│   ├── deploy-all-subscriptions.sh
│   ├── verify-subscriptions.sh
│   └── validate-csv.sh
└── nasuni-single-appliance/   # Single appliance module
    ├── main.tf
    ├── variables.tf
    ├── locals.tf
    ├── outputs.tf
    └── modules/azure/
```

## Best Practices

1. **Always validate CSV before deploying**:
   ```bash
   ./scripts/validate-csv.sh
   ```

2. **Use workspaces for isolation** - Each subscription gets its own workspace and state

3. **Deploy one subscription at a time** - Easier to troubleshoot

4. **Keep resource groups pre-created** - Don't let Terraform create them

5. **Use consistent naming** - Follow your organization's naming conventions

6. **Tag everything** - All 7 required tags are enforced

## Security Notes

- No public IPs are created (per security policy)
- SSH is not enabled in NSG rules
- Admin credentials in `terraform.tfvars` (add to `.gitignore`)
- All resources tagged with owner and regulatory data flags

## Support

For issues:
- **Terraform errors**: Check this README and Terraform docs
- **Azure permissions**: Contact your Azure administrator
- **Nasuni appliance**: Contact Nasuni support
- **Network connectivity**: Verify NSG rules and VNet configuration