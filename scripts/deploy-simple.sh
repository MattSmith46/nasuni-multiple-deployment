#!/bin/bash
set -e

echo "========================================="
echo "Nasuni Multi-Appliance Deployment"
echo "========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform not found. Please install Terraform."
    exit 1
fi
echo "✓ Terraform found: $(terraform version | head -n1)"

if ! command -v az &> /dev/null; then
    echo "❌ Error: Azure CLI not found. Please install Azure CLI."
    exit 1
fi
AZ_VERSION=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo "installed")
echo "✓ Azure CLI found: $AZ_VERSION"

# Check Azure login
if ! az account show &> /dev/null; then
    echo "❌ Error: Not logged into Azure. Please run 'az login'"
    exit 1
fi
echo "✓ Logged into Azure as: $(az account show --query user.name -o tsv)"

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    echo "❌ Error: terraform.tfvars not found"
    echo "   Please copy terraform.tfvars.example and configure it"
    exit 1
fi
echo "✓ terraform.tfvars found"

# Check if appliances.csv exists
if [ ! -f appliances.csv ]; then
    echo "❌ Error: appliances.csv not found"
    exit 1
fi
echo "✓ appliances.csv found"

echo ""
echo "========================================="
echo "Step 1: Creating Resource Groups"
echo "========================================="

# Parse CSV and create both VM and Network resource groups
# Using a simpler approach without associative arrays for compatibility
TEMP_RG_FILE=$(mktemp)

while IFS=, read -r vm_name sub_id env location vm_size cache vm_rg net_rg rest; do
  # Skip header row
  if [[ "$vm_name" != "vm_name" ]] && [[ -n "$sub_id" ]]; then
    
    az account set --subscription "$sub_id" 2>/dev/null || {
      echo "⚠️  Warning: Cannot access subscription $sub_id"
      continue
    }
    
    # Create VM Resource Group
    if [[ -n "$vm_rg" ]]; then
      # Check if we already processed this RG
      if ! grep -q "^${sub_id}:${vm_rg}$" "$TEMP_RG_FILE" 2>/dev/null; then
        echo "${sub_id}:${vm_rg}" >> "$TEMP_RG_FILE"
        echo "Creating VM RG: $vm_rg in $location"
        az group create --name "$vm_rg" --location "$location" --output none 2>/dev/null || {
          echo "   May already exist"
        }
      fi
    fi
    
    # Create Network Resource Group (if different)
    if [[ -n "$net_rg" ]] && [[ "$net_rg" != "$vm_rg" ]]; then
      if ! grep -q "^${sub_id}:${net_rg}$" "$TEMP_RG_FILE" 2>/dev/null; then
        echo "${sub_id}:${net_rg}" >> "$TEMP_RG_FILE"
        echo "Creating Network RG: $net_rg in $location"
        az group create --name "$net_rg" --location "$location" --output none 2>/dev/null || {
          echo "   May already exist"
        }
      fi
    fi
  fi
done < appliances.csv

# Clean up temp file
rm -f "$TEMP_RG_FILE"

echo ""
echo "========================================="
echo "Step 2: Initializing Terraform"
echo "========================================="
echo ""
echo "Note: Marketplace terms will be accepted automatically by Terraform"
echo ""
terraform init

echo ""
echo "========================================="
echo "Step 3: Validating Configuration"
echo "========================================="
terraform validate

echo ""
echo "========================================="
echo "Step 4: Planning Deployment"
echo "========================================="
terraform plan -out=tfplan

echo ""
echo "========================================="
echo "Deployment Plan Ready"
echo "========================================="
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm

if [[ $confirm == "yes" ]]; then
    echo ""
    echo "========================================="
    echo "Step 5: Applying Deployment"
    echo "========================================="
    echo ""
    echo "Note: Terraform will automatically:"
    echo "  1. Accept marketplace terms in all subscriptions"
    echo "  2. Deploy all Nasuni appliances"
    echo ""
    terraform apply tfplan
    rm tfplan
    
    echo ""
    echo "========================================="
    echo "Deployment Complete!"
    echo "========================================="
    echo ""
    echo "View deployment summary:"
    echo "  terraform output deployment_summary"
    echo ""
    echo "View all appliances:"
    echo "  terraform output nasuni_appliances"
    echo ""
    echo "View appliances by subscription:"
    echo "  terraform output subscription_summary"
    echo ""
else
    echo ""
    echo "Deployment cancelled by user"
    rm tfplan
    exit 0
fi