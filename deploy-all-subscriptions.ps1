# ============================================================================
# Nasuni Multi-Subscription Deployment Script (PowerShell)
# Automatically deploys to all workspaces
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    NASUNI MULTI-SUBSCRIPTION DEPLOYMENT                               ║" -ForegroundColor Cyan
Write-Host "║    Using Terraform Workspaces                                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Workspace to subscription mapping
$WORKSPACES = @{
    "pgr" = "c7a18a12-7088-4955-8504-5156e8f48fdd"
    "qis" = "6b025554-fc3d-49a6-a9a1-56d397909042"
    "qti" = "8f054358-9640-4873-a3bf-f1e3547ed39f"
    "nlc" = "c6acb9eb-b6f5-4d21-8794-8585174f9a49"
    "ugc" = "6924ee6e-7efc-40b2-a432-fd4056ff11ed"
    "qco" = "bc1f6e12-bffe-4aa1-84e0-4c3cd6e3a8d4"
    "ims" = "debd8577-362f-4c5f-aafa-d2075a7113fc"
}

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================

Write-Host "Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Terraform found" -ForegroundColor Green

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Azure CLI not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Azure CLI found" -ForegroundColor Green

try {
    $account = az account show | ConvertFrom-Json
    Write-Host "OK: Logged into Azure as: $($account.user.name)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Not logged into Azure. Run 'az login'" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "ERROR: terraform.tfvars not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: terraform.tfvars found" -ForegroundColor Green

if (-not (Test-Path "appliances.csv")) {
    Write-Host "ERROR: appliances.csv not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: appliances.csv found" -ForegroundColor Green

# ============================================================================
# STEP 2: Verify Subscription Access
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Step 1: Verify Subscription Access" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($workspace in $WORKSPACES.Keys | Sort-Object) {
    $sub_id = $WORKSPACES[$workspace]
    Write-Host "Checking $workspace... " -NoNewline
    
    try {
        az account set --subscription $sub_id 2>$null | Out-Null
        $sub_name = az account show --query name -o tsv 2>$null
        Write-Host "OK - $sub_name" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR - No access" -ForegroundColor Red
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

foreach ($workspace in $WORKSPACES.Keys | Sort-Object) {
    $sub_id = $WORKSPACES[$workspace]
    Write-Host "Processing $workspace..." -ForegroundColor Cyan
    
    az account set --subscription $sub_id 2>$null
    az vm image terms accept --publisher nasunicorporation --offer nasuni-nea-90-prod --plan nasuni-nea-9153-prod --output none 2>$null
}

# ============================================================================
# STEP 5: Deploy to Each Subscription
# ============================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Step 4: Deploy to Each Subscription" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($workspace in $WORKSPACES.Keys | Sort-Object) {
    $sub_id = $WORKSPACES[$workspace]
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Workspace: $workspace" -ForegroundColor Cyan
    Write-Host "Subscription: $sub_id" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Create or select workspace
    $workspaceList = terraform workspace list 2>&1
    if ($workspaceList -notmatch "^\s*$workspace\s*$") {
        Write-Host "Creating workspace: $workspace" -ForegroundColor Yellow
        terraform workspace new $workspace 2>$null
    }
    
    terraform workspace select $workspace 2>$null
    
    Write-Host "Planning deployment..." -ForegroundColor Cyan
    terraform plan -out="${workspace}.tfplan"
    
    Write-Host ""
    $response = Read-Host "Deploy to $workspace? (yes/no)"
    
    if ($response -eq "yes") {
        Write-Host "Applying deployment..." -ForegroundColor Green
        terraform apply "${workspace}.tfplan"
        Write-Host "Deployment complete!" -ForegroundColor Green
    }
    else {
        Write-Host "Skipped" -ForegroundColor Yellow
    }
    
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

foreach ($workspace in $WORKSPACES.Keys | Sort-Object) {
    Write-Host "Workspace: $workspace" -ForegroundColor Cyan
    terraform workspace select $workspace 2>$null | Out-Null
    
    try {
        terraform output nasuni_appliances 2>$null
    }
    catch {
        Write-Host "No appliances deployed" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "Done!" -ForegroundColor Green