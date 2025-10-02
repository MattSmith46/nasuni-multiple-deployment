#!/bin/bash
set -e

echo "========================================="
echo "Nasuni Multi-Subscription Deployment"
echo "Using Terraform Workspaces"
echo "========================================="
echo ""

# Workspace to subscription mapping (must match locals.tf)
declare -A WORKSPACES=(
  ["pgr"]="c7a18a12-7088-4955-8504-5156e8f48fdd"
  ["qis"]="6b025554-fc3d-49a6-a9a1-56d397909042"
  ["qti"]="8f054358-9640-4873-a3bf-f1e3547ed39f"
)

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform not found"
    exit 1
fi
echo "✓ Terraform found: $(terraform version | head -n1)"

if ! command -v az &> /dev/null; then
    echo "❌ Error: Azure CLI not found"
    exit 1
fi
echo "✓ Azure CLI found"

if ! az account show &> /dev/null; then
    echo "❌ Error: Not logged into Azure. Run 'az login'"
    exit 1
fi
echo "✓ Logged into Azure as: $(az account show --query user.name -o tsv)"

if [ ! -f terraform.tfvars ]; then
    echo "❌ Error: terraform.tfvars not found"
    exit 1
fi
echo "✓ terraform.tfvars found"

if [ ! -f appliances.csv ]; then
    echo "❌ Error: appliances.csv not found"
    exit 1
fi
echo "✓ appliances.csv found"

echo ""
echo "========================================="
echo "Step 1: Verify Subscription Access"
echo "========================================="
echo ""

# Verify access to all subscriptions
for workspace in "${!WORKSPACES[@]}"; do
  sub_id="${WORKSPACES[$workspace]}"
  printf "%-10s (%s): " "$workspace" "$sub_id"
  
  if az account set --subscription "$sub_id" 2>/dev/null; then
    SUB_NAME=$(az account show --query name -o tsv 2>/dev/null)
    echo "✓ Access confirmed - $SUB_NAME"
  else
    echo "✗ No access"
    echo ""
    echo "❌ Cannot access subscription $sub_id"
    echo "   Please contact your Azure administrator"
    exit 1
  fi
done

echo ""
echo "========================================="
echo "Step 2: Initialize Terraform"
echo "========================================="
echo ""

terraform init

echo ""
echo "========================================="
echo "Step 3: Accept Marketplace Terms"
echo "========================================="
echo ""

for workspace in "${!WORKSPACES[@]}"; do
  sub_id="${WORKSPACES[$workspace]}"
  echo "Accepting terms in $workspace subscription ($sub_id)..."
  
  az account set --subscription "$sub_id"
  az vm image terms accept \
    --publisher nasunicorporation \
    --offer nasuni-nea-90-prod \
    --plan nasuni-nea-9153-prod \
    --output none 2>/dev/null || echo "  (Terms may already be accepted)"
done

echo ""
echo "========================================="
echo "Step 4: Deploy to Each Subscription"
echo "========================================="
echo ""

# Deploy to each workspace
for workspace in "${!WORKSPACES[@]}"; do
  sub_id="${WORKSPACES[$workspace]}"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Deploying to: $workspace"
  echo "Subscription: $sub_id"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Create or select workspace
  if terraform workspace list | grep -q "^\s*$workspace\s*$"; then
    echo "Selecting existing workspace: $workspace"
    terraform workspace select "$workspace"
  else
    echo "Creating new workspace: $workspace"
    terraform workspace new "$workspace"
  fi
  
  echo ""
  echo "Planning deployment..."
  terraform plan -out="${workspace}.tfplan"
  
  echo ""
  read -p "Deploy to $workspace subscription? (yes/no): " confirm
  
  if [[ $confirm == "yes" ]]; then
    echo ""
    echo "Deploying to $workspace..."
    terraform apply "${workspace}.tfplan"
    rm -f "${workspace}.tfplan"
    
    echo ""
    echo "✓ Deployment to $workspace complete!"
    echo ""
    echo "Outputs:"
    terraform output -json nasuni_appliances | jq -r 'to_entries[] | "\(.key): \(.value.private_ip)"'
  else
    echo ""
    echo "Skipping deployment to $workspace"
    rm -f "${workspace}.tfplan"
  fi
  
  echo ""
done

echo ""
echo "========================================="
echo "Deployment Summary"
echo "========================================="
echo ""

# Show summary for each workspace
for workspace in "${!WORKSPACES[@]}"; do
  echo "Workspace: $workspace"
  terraform workspace select "$workspace" > /dev/null 2>&1
  
  if terraform output nasuni_appliances &> /dev/null; then
    terraform output -json nasuni_appliances | jq -r 'to_entries[] | "  \(.key): \(.value.private_ip) (\(.value.vm_name))"'
  else
    echo "  No appliances deployed"
  fi
  echo ""
done

echo "========================================="
echo "All Done!"
echo "========================================="
echo ""
echo "To view details for a specific workspace:"
echo "  terraform workspace select <workspace-name>"
echo "  terraform output nasuni_appliances"
echo ""
echo "To add more appliances:"
echo "  1. Add rows to appliances.csv"
echo "  2. terraform workspace select <workspace>"
echo "  3. terraform apply"
echo ""