# Nasuni Multi-Appliance Deployment - Multi-Subscription

Deploy multiple Nasuni Edge Appliances across multiple Azure subscriptions using CSV configuration.

## Prerequisites

1. Azure CLI authenticated with access to ALL subscriptions
2. Terraform >= 1.0
3. Access to the single-appliance Terraform module
4. Resource Groups pre-created in each subscription
5. Appropriate permissions in each subscription

## Repository Structure

```
nasuni-multi-deploy/           # This repository
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── terraform.tfvars.example
├── appliances.csv
└── README.md

## Quick Start

### 1. Clone Repository

```bash
git clone <this-repo-url>
cd nasuni-multi-deploy
```

### 2. Configure terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your subscription IDs and credentials
```

### 3. Update appliances.csv

Edit `appliances.csv` with your actual:
- Subscription IDs
- VM names
- Locations
- Resource group names
- Network configurations

### 4. Authenticate to Azure

```bash
az login
az account list --output table
```

### 5. Create Resource Groups

```bash
# For each subscription and resource group in your CSV
az account set --subscription "your-subscription-id"
az group create --name "your-rg-name" --location "your-location"
```

### 6. Accept Marketplace Terms

```bash
# Run for each subscription
az account set --subscription "your-subscription-id"
az vm image terms accept \
  --publisher nasunicorporation \
  --offer nasuni-nea-90-prod \
  --plan nasuni-nea-9153-prod
```

### 7. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## CSV Column Reference

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| vm_name | Yes | Unique VM name | nasuni-nea-houston |
| subscription_id | Yes | Azure subscription ID | aaaaa-1111-... |
| environment | Yes | Environment (PD/NP/DR) | PD |
| location | Yes | Azure region | South Central US |
| vm_size | Yes | Azure VM size | Standard_D4s_v3 |
| cache_disk_size_gb | Yes | Cache disk size | 512 |
| resource_group_name | Yes | Resource group (must exist) | nasuni-houston-rg |
| network_cidr | No | VNet CIDR (if creating new) | 10.1.0.0/16 |
| subnet_cidr | No | Subnet CIDR (if creating new) | 10.1.1.0/24 |
| existing_vnet_resource_group | No | RG of existing VNet | existing-network-rg |
| existing_vnet_name | No | Existing VNet name | my-vnet |
| existing_subnet_name | No | Existing subnet name | nasuni-subnet |
| storage_account_name | No | Existing storage account | mystorageacct |
| enable_virtual_wan | No | Enable vWAN (true/false) | false |
| site | No | Site identifier | Houston |
| critical_infrastructure | Yes | Critical infrastructure flag | Yes/No |
| external_facing | Yes | External facing flag | Yes/No |
| owner | Yes | Owner email | user@quantaservices.com |
| project_name | Yes | Project name | Nasuni |
| regulatory_data | Yes | Regulatory data flag | Yes/No |
| service | Yes | Service name | Nasuni |

## Required Tags

All resources are tagged with the following mandatory tags from the CSV:

```
critical-infrastructure: Yes/No
environment: PD/NP/DR
external-facing: Yes/No
owner: email@quantaservices.com
project-name: Nasuni
regulatory-data: Yes/No
Service: Nasuni
```

## Multi-Subscription Setup

### Authentication

**Option 1: Azure CLI (Development)**

```bash
az login
az account list --output table
```

**Option 2: Service Principal (Production/CI-CD)**

```bash
az ad sp create-for-rbac --name "nasuni-terraform-sp" \
  --role Contributor \
  --scopes \
    /subscriptions/sub-id-1 \
    /subscriptions/sub-id-2 \
    /subscriptions/sub-id-3
```

Set environment variables:
```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<default_subscription_id>"
export ARM_TENANT_ID="<tenant>"
```

### Adding More Subscriptions

If you need more than 4 subscriptions:

1. Add to `variables.tf`:
```hcl
variable "subscription_aliases" {
  default = {
    sub1 = ""
    sub2 = ""
    sub3 = ""
    sub4 = ""
    sub5 = ""  # Add more here
    sub6 = ""
  }
}
```

2. Add provider blocks to `main.tf`:
```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  alias           = "sub5"
  subscription_id = var.subscription_aliases["sub5"]
}
```

## Helper Scripts

### Create All Resource Groups

```bash
#!/bin/bash
# create-resource-groups.sh

while IFS=, read -r vm_name sub_id env location vm_size cache rg rest; do
  if [[ "$vm_name" != "vm_name" ]] && [[ -n "$sub_id" ]] && [[ -n "$rg" ]]; then
    echo "Creating RG: $rg in subscription $sub_id"
    az account set --subscription "$sub_id"
    az group create --name "$rg" --location "$location" --output none || true
  fi
done < appliances.csv
```

### Accept Terms in All Subscriptions

```bash
#!/bin/bash
# accept-marketplace-terms.sh

SUBSCRIPTIONS=(
  "aaaaaaaa-1111-1111-1111-111111111111"
  "bbbbbbbb-2222-2222-2222-222222222222"
  "cccccccc-3333-3333-3333-333333333333"
  "dddddddd-4444-4444-4444-444444444444"
)

for sub in "${SUBSCRIPTIONS[@]}"; do
  echo "Accepting terms in subscription: $sub"
  az account set --subscription "$sub"
  az vm image terms accept \
    --publisher nasunicorporation \
    --offer nasuni-nea-90-prod \
    --plan nasuni-nea-9153-prod \
    --output none
done
```

### Verify Subscription Access

```bash
#!/bin/bash
# verify-subscriptions.sh

while IFS=, read -r vm_name sub_id rest; do
  if [[ "$vm_name" != "vm_name" ]] && [[ -n "$sub_id" ]]; then
    echo -n "Checking subscription $sub_id: "
    if az account set --subscription "$sub_id" 2>/dev/null; then
      echo "✓ Access confirmed"
    else
      echo "✗ No access"
    fi
  fi
done < appliances.csv
```

## Network Configuration

### Option 1: Create New Network (Default)

Leave existing network fields empty in CSV:

```csv
vm_name,...,network_cidr,subnet_cidr,existing_vnet_resource_group,existing_vnet_name,existing_subnet_name
nasuni-nea-01,...,10.1.0.0/16,10.1.1.0/24,,,
```

### Option 2: Use Existing Network

Specify existing network details:

```csv
vm_name,...,network_cidr,subnet_cidr,existing_vnet_resource_group,existing_vnet_name,existing_subnet_name
nasuni-nea-02,,...,,network-rg,prod-vnet,nasuni-subnet
```

## Managing Deployments

### View Deployment Status

```bash
# All appliances
terraform output nasuni_appliances

# Summary by subscription
terraform output subscription_summary

# Full deployment summary
terraform output deployment_summary
```

### Deploy Specific Appliances

```bash
# Deploy only Houston appliance
terraform apply -target='module.nasuni_appliances["nasuni-nea-houston"]'

# Deploy multiple specific appliances
terraform apply \
  -target='module.nasuni_appliances["nasuni-nea-houston"]' \
  -target='module.nasuni_appliances["nasuni-nea-dallas"]'
```

### Add New Appliances

1. Add new row to `appliances.csv`
2. Create the resource group (if needed)
3. Run `terraform apply`

Only the new appliance will be created.

### Remove Appliances

1. Remove row from `appliances.csv`
2. Run `terraform apply`

Or use targeted destroy:
```bash
terraform destroy -target='module.nasuni_appliances["nasuni-nea-houston"]'
```

### Update Existing Appliances

Modify the CSV row and run `terraform apply`. 

**Note:** Some changes (like VM size, location) may require resource recreation.

## Outputs

### View Appliance Details

```bash
# Specific appliance
terraform output -json nasuni_appliances | jq '.["nasuni-nea-houston"]'

# All appliances with IPs
terraform output -json nasuni_appliances | jq '.[] | {vm_name, private_ip}'

# Appliances by subscription
terraform output subscription_summary
```

### Example Output

```json
{
  "nasuni-nea-houston": {
    "admin_console_url": "https://10.1.1.4:8443",
    "private_ip": "10.1.1.4",
    "resource_group_name": "nasuni-houston-rg",
    "ssh_command": "ssh azureuser@10.1.1.4",
    "subscription_id": "aaaaaaaa-1111-1111-1111-111111111111",
    "vm_name": "nasuni-nea-houston"
  }
}
```

## Troubleshooting

### Authentication Failed

```bash
# Check current subscription
az account show

# List all subscriptions
az account list --output table

# Switch subscription
az account set --subscription "<subscription-id>"
```

### Marketplace Terms Not Accepted

```bash
az account set --subscription "<subscription-id>"
az vm image terms accept \
  --publisher nasunicorporation \
  --offer nasuni-nea-90-prod \
  --plan nasuni-nea-9153-prod
```

### Resource Group Not Found

```bash
az account set --subscription "<subscription-id>"
az group create --name "<rg-name>" --location "<location>"
```

### Permission Denied

Verify role assignments:
```bash
az role assignment list --assignee <your-user-or-sp> --subscription <subscription-id>
```

You need at least `Contributor` role.

### Network CIDR Conflicts

Ensure non-overlapping ranges across subscriptions if planning to peer VNets:

```csv
# Subscription 1 - 10.1.x.x
nasuni-nea-01,sub1,...,10.1.0.0/16,10.1.1.0/24

# Subscription 2 - 10.2.x.x  
nasuni-nea-02,sub2,...,10.2.0.0/16,10.2.1.0/24
```

## Best Practices

### 1. Subscription Organization

- **Subscription 1**: Production - Primary Region
- **Subscription 2**: Production - Secondary Region
- **Subscription 3**: Disaster Recovery
- **Subscription 4**: Development/Test

### 2. Network Planning

Use non-overlapping CIDR blocks:
- Sub 1: 10.1.x.x/16
- Sub 2: 10.2.x.x/16
- Sub 3: 10.3.x.x/16
- Sub 4: 10.4.x.x/16

### 3. Naming Convention

```
nasuni-nea-<location>
nasuni-<location>-rg
```

### 4. State Management

For production, use remote state:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<unique>"
    container_name       = "tfstate"
    key                  = "nasuni-multi.terraform.tfstate"
  }
}
```

### 5. Security

- Store passwords in Azure Key Vault
- Use Service Principal with least privilege
- Enable activity logging in all subscriptions
- Review NSG rules regularly
- No public IPs (per security policy)

## Cost Management

### Track Costs by Tag

```bash
# View costs by owner
az consumption usage list \
  --subscription "<subscription-id>" \
  --start-date 2025-09-01 \
  --end-date 2025-09-30 \
  --filter "tags/owner eq 'cwilliford@quantaservices.com'"
```

### Cost Optimization

- Use **Standard_D4s_v3** for standard workloads (4 vCPU, 16 GB)
- Use **Standard_D8s_v3** for high-performance needs (8 vCPU, 32 GB)
- Consider **StandardSSD_LRS** for non-production cache disks
- Review and right-size after monitoring

## Support

For issues with:
- **Terraform configuration**: Check this README and Terraform docs
- **Azure permissions**: Contact your Azure administrator
- **Nasuni appliance**: Contact Nasuni support
- **Network connectivity**: Verify NSG rules and VNet configuration

## License

[Your License Here]

## Contact

**Owner**: cwilliford@quantaservices.com  
**Project**: Nasuni Edge Appliance Deployment