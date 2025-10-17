# ============================================================================
# Nasuni Multi-Subscription Deployment Script (PowerShell)
# Automatically deploys to all workspaces (pgr, qis, qti)
# ============================================================================

Write-Host @"

╔════════════════════════════════════════════════════════════════════════╗
║    NASUNI MULTI-SUBSCRIPTION DEPLOYMENT                               ║
║    Using Terraform Workspaces                                         ║
╚════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Workspace to subscription mapping (must match locals.tf)
$WORKSPACES = @{
    "pgr" = "c7a18a12-7088-4955-8504-5156e8f48fdd"
    "qis" = "6b025554-fc3d-49a6-a9a1-56d397909042"
    "qti" = "8f054358-9640-4873-a3bf-f1e3547ed39f"
}

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================

Write-Host "Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

# Check Terraform
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Terraform not found" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Terraform found: $(terraform version | Select-Object -First 1)" -ForegroundColor Green

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Azure CLI not found" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Azure CLI found" -ForegroundColor Green

# Check Azure login
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✓ Logged into Azure as: $($account.user.name)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: Not logged into Azure. Run 'az login'" -ForegroundColor Red
    exit 1
}

# Check terraform.tfvars
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "❌ Error: terraform.tfvars not found" -ForegroundColor Red
    exit 1
}
Write-Host "✓ terraform.tfvars found" -ForegroundColor Green

# Check appliances.csv
if (-not (Test-Path "appliances.csv")) {
    Write-Host "❌ Error: appliances.csv not found" -ForegroundColor Red
    exit 1
}
Write-Host "✓ appliances.csv found" -ForegroundColor Green

# ============================================================================
# STEP 2: Verify Subscription Access
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Step 1: Verify Subscription Access" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($workspace in $WORKSPACES.Keys) {
    $sub_id = $WORKSPACES[$workspace]
    Write-Host "Checking $workspace ($sub_id)... " -NoNewline
    
    try {
        az account set --subscription $sub_id 2>$null | Out-Null
        $sub_name = az account show --query name -o tsv 2>$null
        Write-Host "✓ Access confirmed - $sub_name" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ No access" -ForegroundColor Red
        Write-Host ""
        Write-Host "❌ Cannot access subscription $sub_id" -ForegroundColor Red
        Write-Host "   Please contact your Azure administrator" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STEP 3: Initialize Terraform
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Step 2: Initialize Terraform" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

terraform init

# ============================================================================
# STEP 4: Accept Marketplace Terms
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Step 3: Accept Marketplace Terms" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($workspace in $WORKSPACES.Keys) {
    $sub_id = $WORKSPACES[$workspace]
    Write-Host "Accepting terms in $workspace subscription ($sub_id)..." -ForegroundColor Cyan
    
    az account set --subscription $sub_id 2>$null
    az vm image terms accept `
        --publisher nasunicorporation `
        --offer nasuni-nea-90-prod `
        --plan nasuni-nea-9153-prod `
        --output none 2>$null
    
    Write-Host "  ✓ Done" -ForegroundColor Green
}

# ============================================================================
# STEP 5: Deploy to Each Subscription
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Step 4: Deploy to Each Subscription" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$deploymentResults = @()

foreach ($workspace in $WORKSPACES.Keys) {
    $sub_id = $WORKSPACES[$workspace]
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Deploying to: $workspace" -ForegroundColor Cyan
    Write-Host "Subscription: $sub_id" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if workspace exists, if not create it
    $workspaceList = terraform workspace list 2>&1
    if ($workspaceList -notmatch "^\s*$workspace\s*$") {
        Write-Host "Creating new workspace: $workspace" -ForegroundColor Yellow
        terraform workspace new $workspace 2>$null
    }
    else {
        Write-Host "Selecting existing workspace: $workspace" -ForegroundColor Yellow
    }
    
    # Select workspace
    terraform workspace select $workspace 2>$null
    
    Write-Host ""
    Write-Host "Planning deployment..." -ForegroundColor Cyan
    terraform plan -out="${workspace}.tfplan"
    
    Write-Host ""
    $response = Read-Host "Deploy to $workspace subscription? (yes/no)"
    
    if ($response -eq "yes") {
        Write-Host ""
        Write-Host "Deploying to $workspace..." -ForegroundColor Green
        terraform apply "${workspace}.tfplan"
        
        Write-Host ""
        Write-Host "✓ Deployment to $workspace complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Outputs:" -ForegroundColor Cyan
        
        try {
            $outputs = terraform output -json nasuni_appliances 2>$null | ConvertFrom-Json
            foreach ($vm in $outputs.PSObject.Properties) {
                Write-Host "  $($vm.Name): $($vm.Value.private_ip)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  Could not retrieve outputs" -ForegroundColor Yellow
        }
        
        $deploymentResults += @{ Workspace = $workspace; Status = "Success" }
    }
    else {
        Write-Host ""
        Write-Host "Skipping deployment to $workspace" -ForegroundColor Yellow
        $deploymentResults += @{ Workspace = $workspace; Status = "Skipped" }
    }
    
    # Clean up plan file
    Remove-Item "${workspace}.tfplan" -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
}

# ============================================================================
# STEP 6: Summary
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($workspace in $WORKSPACES.Keys) {
    Write-Host "Workspace: $workspace" -ForegroundColor Cyan
    terraform workspace select $workspace 2>$null | Out-Null
    
    try {
        $outputs = terraform output -json nasuni_appliances 2>$null | ConvertFrom-Json
        foreach ($vm in $outputs.PSObject.Properties) {
            Write-Host "  ✓ $($vm.Name): $($vm.Value.private_ip)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  No appliances deployed" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "All Done!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view details for a specific workspace:" -ForegroundColor Cyan
Write-Host "  terraform workspace select <workspace-name>" -ForegroundColor Cyan
Write-Host "  terraform output nasuni_appliances" -ForegroundColor Cyan
Write-Host ""