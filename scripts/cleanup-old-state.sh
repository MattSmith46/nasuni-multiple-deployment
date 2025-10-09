#!/bin/bash
set -e

echo "========================================="
echo "Cleanup Old Terraform State"
echo "========================================="
echo ""
echo "⚠️  WARNING: This script removes old module references from state"
echo "   Only run this if you migrated from a multi-provider to workspace architecture"
echo ""

read -p "Have you backed up your state file? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "Please backup your state file first:"
    echo "  cp terraform.tfstate terraform.tfstate.pre-cleanup-backup"
    exit 1
fi

echo ""
echo "Checking for old module references..."
echo ""

# List current state
OLD_MODULES=$(terraform state list 2>/dev/null | grep -E 'module\.nasuni_appliances_(pgr|qis|qti)' || true)

if [[ -z "$OLD_MODULES" ]]; then
    echo "✓ No old module references found"
    echo "  Your state is clean!"
    exit 0
fi

echo "Found old module references:"
echo "$OLD_MODULES"
echo ""

read -p "Remove these from state? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "Cancelled by user"
    exit 0
fi

echo ""
echo "Removing old module references..."
echo ""

while IFS= read -r module; do
    if [[ -n "$module" ]]; then
        echo "Removing: $module"
        terraform state rm "$module" || echo "  Failed to remove (may not exist)"
    fi
done <<< "$OLD_MODULES"

echo ""
echo "========================================="
echo "Cleanup Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Verify: terraform state list"
echo "  2. Initialize: terraform init -reconfigure"
echo "  3. Select workspace: terraform workspace select <workspace>"
echo "  4. Plan: terraform plan"
echo ""
echo "If resources are now unmanaged, you can re-import them:"
echo "  terraform import 'module.nasuni_appliances[\"VM-NAME\"]...' /subscriptions/..."
echo ""