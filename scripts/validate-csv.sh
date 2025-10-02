#!/bin/bash

echo "========================================="
echo "Validate appliances.csv"
echo "========================================="
echo ""

# Check if CSV exists
if [ ! -f appliances.csv ]; then
    echo "❌ Error: appliances.csv not found"
    exit 1
fi

ERROR_COUNT=0
WARNING_COUNT=0
LINE_NUM=0

# Expected column count (22 columns - added network_resource_group_name)
EXPECTED_COLS=22

echo "Checking CSV format and required fields..."
echo ""

while IFS=, read -r vm_name sub_id env location vm_size cache vm_rg net_rg net_cidr sub_cidr ex_vnet_rg ex_vnet ex_sub sa vwan site crit ext owner proj reg svc rest; do
  ((LINE_NUM++))
  
  # Skip header
  if [[ "$vm_name" == "vm_name" ]]; then
    continue
  fi
  
  # Count columns
  COL_COUNT=$(echo "$vm_name,$sub_id,$env,$location,$vm_size,$cache,$vm_rg,$net_rg,$net_cidr,$sub_cidr,$ex_vnet_rg,$ex_vnet,$ex_sub,$sa,$vwan,$site,$crit,$ext,$owner,$proj,$reg,$svc" | awk -F',' '{print NF}')
  
  if [ "$COL_COUNT" -ne "$EXPECTED_COLS" ]; then
    echo "Line $LINE_NUM: ❌ Column count mismatch (expected $EXPECTED_COLS, got $COL_COUNT)"
    ((ERROR_COUNT++))
  fi
  
  # Validate required fields
  if [[ -z "$vm_name" ]]; then
    echo "Line $LINE_NUM: ❌ Missing vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$sub_id" ]]; then
    echo "Line $LINE_NUM: ❌ Missing subscription_id"
    ((ERROR_COUNT++))
  elif [[ ! "$sub_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: subscription_id format may be invalid for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  if [[ -z "$env" ]]; then
    echo "Line $LINE_NUM: ❌ Missing environment for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$location" ]]; then
    echo "Line $LINE_NUM: ❌ Missing location for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$vm_size" ]]; then
    echo "Line $LINE_NUM: ❌ Missing vm_size for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$cache" ]]; then
    echo "Line $LINE_NUM: ❌ Missing cache_disk_size_gb for $vm_name"
    ((ERROR_COUNT++))
  elif ! [[ "$cache" =~ ^[0-9]+$ ]]; then
    echo "Line $LINE_NUM: ❌ cache_disk_size_gb must be a number for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$vm_rg" ]]; then
    echo "Line $LINE_NUM: ❌ Missing resource_group_name for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$net_rg" ]]; then
    echo "Line $LINE_NUM: ❌ Missing network_resource_group_name for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  # Validate network configuration
  if [[ -z "$ex_vnet" ]] && [[ -z "$net_cidr" ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: No existing VNet or network_cidr specified for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  if [[ -n "$ex_vnet" ]] && [[ -z "$ex_vnet_rg" ]]; then
    echo "Line $LINE_NUM: ⚠️  Info: No existing_vnet_resource_group specified for $vm_name (will use network_resource_group_name)"
  fi
  
  if [[ -n "$ex_vnet" ]] && [[ -z "$ex_sub" ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: Existing VNet specified but no subnet for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  # Validate required tags
  if [[ -z "$crit" ]]; then
    echo "Line $LINE_NUM: ❌ Missing critical_infrastructure for $vm_name"
    ((ERROR_COUNT++))
  elif [[ "$crit" != "Yes" ]] && [[ "$crit" != "No" ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: critical_infrastructure should be 'Yes' or 'No' for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  if [[ -z "$ext" ]]; then
    echo "Line $LINE_NUM: ❌ Missing external_facing for $vm_name"
    ((ERROR_COUNT++))
  elif [[ "$ext" != "Yes" ]] && [[ "$ext" != "No" ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: external_facing should be 'Yes' or 'No' for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  if [[ -z "$owner" ]]; then
    echo "Line $LINE_NUM: ❌ Missing owner for $vm_name"
    ((ERROR_COUNT++))
  elif [[ ! "$owner" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: owner email format may be invalid for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  if [[ -z "$proj" ]]; then
    echo "Line $LINE_NUM: ❌ Missing project_name for $vm_name"
    ((ERROR_COUNT++))
  fi
  
  if [[ -z "$reg" ]]; then
    echo "Line $LINE_NUM: ❌ Missing regulatory_data for $vm_name"
    ((ERROR_COUNT++))
  elif [[ "$reg" != "Yes" ]] && [[ "$reg" != "No" ]]; then
    echo "Line $LINE_NUM: ⚠️  Warning: regulatory_data should be 'Yes' or 'No' for $vm_name"
    ((WARNING_COUNT++))
  fi
  
  if [[ -z "$svc" ]]; then
    echo "Line $LINE_NUM: ❌ Missing service for $vm_name"
    ((ERROR_COUNT++))
  fi
  
done < appliances.csv

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Total lines checked: $((LINE_NUM - 1))"
echo "❌ Errors: $ERROR_COUNT"
echo "⚠️  Warnings: $WARNING_COUNT"
echo ""

if [ $ERROR_COUNT -gt 0 ]; then
  echo "❌ CSV validation failed"
  echo "   Please fix the errors above before deploying"
  exit 1
elif [ $WARNING_COUNT -gt 0 ]; then
  echo "⚠️  CSV validation passed with warnings"
  echo "   Review warnings above - deployment may still work"
  exit 0
else
  echo "✓ CSV validation passed"
  echo "   Your CSV is ready for deployment"
fi