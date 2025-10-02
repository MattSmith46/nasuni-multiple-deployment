#!/bin/bash

echo "========================================="
echo "Subscription Access Verification"
echo "========================================="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Error: Azure CLI not found"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Error: Not logged into Azure. Please run 'az login'"
    exit 1
fi

echo "Current user: $(az account show --query user.name -o tsv)"
echo ""

# Check if appliances.csv exists
if [ ! -f appliances.csv ]; then
    echo "❌ Error: appliances.csv not found"
    exit 1
fi

echo "Checking subscription access..."
echo ""

# Extract unique subscription IDs and verify access
declare -A checked_subs
SUCCESS_COUNT=0
FAIL_COUNT=0

while IFS=, read -r vm_name sub_id rest; do
  # Skip header and empty lines
  if [[ "$vm_name" != "vm_name" ]] && [[ -n "$sub_id" ]] && [[ -z "${checked_subs[$sub_id]}" ]]; then
    checked_subs[$sub_id]=1
    
    printf "%-40s " "$sub_id"
    
    if az account set --subscription "$sub_id" 2>/dev/null; then
      SUB_NAME=$(az account show --query name -o tsv 2>/dev/null)
      echo "✓ Access confirmed - $SUB_NAME"
      ((SUCCESS_COUNT++))
    else
      echo "✗ No access"
      ((FAIL_COUNT++))
    fi
  fi
done < appliances.csv

echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo "✓ Accessible subscriptions: $SUCCESS_COUNT"
echo "✗ Inaccessible subscriptions: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
  echo "⚠️  Warning: You don't have access to all subscriptions in the CSV"
  echo "   Please contact your Azure administrator for access"
  exit 1
else
  echo "✓ All subscriptions are accessible"
  echo "   You can proceed with deployment"
fi