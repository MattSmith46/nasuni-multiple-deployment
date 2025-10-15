# ============================================================================
# Nasuni Edge Appliance Automation - Multi-Subscription Deployment
# Integrated with Terraform Workspace Architecture
# ============================================================================
# Automatically configures Nasuni Edge Appliances after Terraform deployment
# Reads IP addresses from Terraform outputs - no manual IP entry needed!
#
# Usage:
#   pwsh Deploy-NasuniAutomation.ps1 -Workspace pgr
#   pwsh Deploy-NasuniAutomation.ps1 -Mode all
#   pwsh Deploy-NasuniAutomation.ps1 -Mode specific -Appliances "VM1","VM2"
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$VariablesPath = "./Variables.ps1",
    
    [Parameter(Mandatory=$false)]
    [string]$TerraformDirectory = ".",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("workspace", "all", "specific")]
    [string]$Mode,
    
    [Parameter(Mandatory=$false)]
    [string]$Workspace,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Appliances,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxWaitMinutes = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConnectivityTest,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host @"

╔════════════════════════════════════════════════════════════════════════╗
║    NASUNI EDGE APPLIANCE AUTOMATION                                   ║
║    Multi-Subscription Workspace Integration                           ║
╚════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$scriptStartTime = Get-Date
Write-Host "[INFO] Started: $($scriptStartTime.ToString('yyyy-MM-dd HH:mm:ss'))`n" -ForegroundColor Cyan

# Validate PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 6) {
    Write-Error "PowerShell 6+ required. Current: $psVersion. Install: winget install Microsoft.PowerShell"
    exit 1
}
Write-Host "[OK] PowerShell: $psVersion" -ForegroundColor Green

# Load configuration
Write-Host "`n[STEP 1] Loading configuration..." -ForegroundColor Yellow
if (-not (Test-Path $VariablesPath)) {
    Write-Error "Variables file not found: $VariablesPath"
    exit 1
}

try {
    . $VariablesPath
    Write-Host "[OK] Configuration loaded" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load Variables.ps1: $_"
    exit 1
}

# Override from parameters
if ($Mode) { $script:DeploymentMode = $Mode }
if ($Appliances -and $Appliances.Count -gt 0) {
    $script:TargetAppliances = $Appliances
    $script:DeploymentMode = "specific"
}

# Validation
if (-not $SkipValidation) {
    if (Get-Command Test-Configuration -ErrorAction SilentlyContinue) {
        if (-not (Test-Configuration)) {
            Write-Error "Configuration validation failed"
            exit 1
        }
    }
}

# Load CSV
Write-Host "`n[STEP 2] Loading appliances from CSV..." -ForegroundColor Yellow
if (-not (Test-Path $AppliancesCsvPath)) {
    Write-Error "CSV not found: $AppliancesCsvPath"
    exit 1
}

$csvData = Import-Csv -Path $AppliancesCsvPath
Write-Host "[OK] Loaded $($csvData.Count) appliances" -ForegroundColor Green

# Get Terraform info
Write-Host "`n[STEP 3] Retrieving Terraform information..." -ForegroundColor Yellow
$originalDir = Get-Location
Set-Location $TerraformDirectory

$currentWorkspace = "default"
$terraformOutputs = $null

try {
    if (Test-Path ".terraform") {
        $currentWorkspace = terraform workspace show 2>$null
        
        if ($Workspace -and $Workspace -ne $currentWorkspace) {
            Write-Host "[INFO] Switching to workspace: $Workspace" -ForegroundColor Cyan
            terraform workspace select $Workspace 2>$null
            $currentWorkspace = $Workspace
        }
        
        Write-Host "[OK] Workspace: $currentWorkspace" -ForegroundColor Green
        
        $tfOutputJson = terraform output -json 2>$null
        if ($LASTEXITCODE -eq 0 -and $tfOutputJson) {
            $terraformOutputs = $tfOutputJson | ConvertFrom-Json
            Write-Host "[OK] Retrieved Terraform outputs" -ForegroundColor Green
        }
    }
    else {
        Write-Warning "Terraform not initialized"
    }
}
catch {
    Write-Warning "Error getting Terraform info: $_"
}
finally {
    Set-Location $originalDir
}

# Determine appliances
Write-Host "`n[STEP 4] Determining appliances..." -ForegroundColor Yellow
$appliancesToConfigure = @()

switch ($DeploymentMode) {
    "workspace" {
        if ($WorkspaceSubscriptions.ContainsKey($currentWorkspace)) {
            $workspaceSubId = $WorkspaceSubscriptions[$currentWorkspace]
            $appliancesToConfigure = $csvData | Where-Object { $_.subscription_id -eq $workspaceSubId }
            Write-Host "[INFO] Mode: Workspace ($currentWorkspace)" -ForegroundColor Cyan
        }
        else {
            Write-Error "Workspace '$currentWorkspace' not in mapping"
            exit 1
        }
    }
    "all" {
        $appliancesToConfigure = $csvData
        Write-Host "[INFO] Mode: All appliances" -ForegroundColor Cyan
    }
    "specific" {
        $appliancesToConfigure = $csvData | Where-Object { $TargetAppliances -contains $_.vm_name }
        Write-Host "[INFO] Mode: Specific" -ForegroundColor Cyan
    }
}

if ($appliancesToConfigure.Count -eq 0) {
    Write-Error "No appliances found"
    exit 1
}

Write-Host "[OK] Found $($appliancesToConfigure.Count) appliance(s):" -ForegroundColor Green
foreach ($app in $appliancesToConfigure) {
    Write-Host "  - $($app.vm_name)" -ForegroundColor Cyan
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Exiting" -ForegroundColor Yellow
    exit 0
}

# Download automation script
Write-Host "`n[STEP 5] Preparing scripts..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$autoDeployPath = Join-Path $scriptDir "AutodeployEA.ps1"

if (-not (Test-Path $autoDeployPath)) {
    Write-Host "[INFO] Downloading AutodeployEA.ps1..." -ForegroundColor Cyan
    $githubUrl = "https://raw.githubusercontent.com/nasuni-labs/nasuni-edgeappliance-automation/main/AutodeployEA.ps1"
    Invoke-WebRequest -Uri $githubUrl -OutFile $autoDeployPath
    Write-Host "[OK] Downloaded" -ForegroundColor Green
}
else {
    Write-Host "[OK] Using existing AutodeployEA.ps1" -ForegroundColor Green
}

# Configure appliances
Write-Host "`n[STEP 6] Configuring appliances..." -ForegroundColor Yellow
$results = @()
$successCount = 0
$failureCount = 0

foreach ($appliance in $appliancesToConfigure) {
    $applianceName = $appliance.vm_name
    
    Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $($applianceName.PadRight(44)) ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    try {
        # Get settings
        $settings = Get-ApplianceSettings -ApplianceName $applianceName -CsvData @{
            vm_name = $appliance.vm_name
            subscription_id = $appliance.subscription_id
            environment = $appliance.environment
            location = $appliance.location
            storage_account_name = $appliance.storage_account_name
        }
        
        # Get private IP (AUTO-DETECTED!)
        $privateIp = $null
        if ($terraformOutputs -and $terraformOutputs.nasuni_appliances) {
            $appOut = $terraformOutputs.nasuni_appliances.value.$applianceName
            if ($appOut) {
                $privateIp = $appOut.private_ip
                Write-Host "[OK] IP from Terraform: $privateIp" -ForegroundColor Green
            }
        }
        
        # Fallback to Azure CLI
        if (-not $privateIp) {
            Write-Host "[INFO] Getting IP from Azure..." -ForegroundColor Yellow
            $privateIp = az vm show -g $appliance.resource_group_name -n $applianceName --show-details --query "privateIps" -o tsv 2>$null
            if ($privateIp) {
                Write-Host "[OK] IP from Azure: $privateIp" -ForegroundColor Green
            }
        }
        
        if (-not $privateIp) {
            throw "Could not determine private IP"
        }
        
        # Test connectivity
        if (-not $SkipConnectivityTest) {
            Write-Host "[CHECK] Testing connectivity..." -ForegroundColor Cyan
            $connected = $false
            $attempts = 0
            
            while (-not $connected -and $attempts -lt ($MaxWaitMinutes * 2)) {
                $attempts++
                if (Test-Connection -ComputerName $privateIp -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                    Write-Host "[OK] Reachable" -ForegroundColor Green
                    $connected = $true
                }
                else {
                    Write-Host "[WAIT] Not responding ($attempts)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 30
                }
            }
            
            if (-not $connected) {
                throw "Not reachable after $MaxWaitMinutes minutes"
            }
        }
        
        # Create temp variables
        $tempVarPath = [System.IO.Path]::GetTempFileName() + ".ps1"
        $storageKey = Get-StorageAccountKey -StorageAccountName $appliance.storage_account_name
        
        @"
`$EdgeApplianceIpAddress = "$privateIp"
`$EdgeApplianceName = "$applianceName"
`$NmcHostname = "$NmcHostname"
`$NmcUsername = "$NmcUsername"
`$NmcPassword = '$NmcPassword'
`$SerialNumber = ""
`$AuthCode = ""
`$bootproto = 'dhcp'
`$gateway = '$($settings.Gateway)'
`$search_domain = '$($settings.SearchDomain)'
`$primary_dns = '$($settings.PrimaryDns)'
`$secondary_dns = '$($settings.SecondaryDns)'
`$NwTG1Proto = '$(if ($settings.UseStaticIP) { "static" } else { "dhcp" })'
`$NwTG1Ipaddr = '$($settings.StaticIP)'
`$NwTG1Netmask = '$($settings.Netmask)'
`$NwTG1Mtu = '1500'
`$JoinActiveDirectory = `$$($settings.JoinAD)
`$AdDomain = '$($settings.AdDomain)'
`$AdUsername = '$($settings.AdUsername)'
`$AdPassword = '$($settings.AdPassword)'
`$Timezone = '$($settings.Timezone)'
`$CloudProvider = 'azure'
`$AzureStorageAccount = '$($appliance.storage_account_name)'
`$AzureStorageKey = '$storageKey'
`$AcceptEula = `$true
`$SkipUpdates = `$true
"@ | Out-File -FilePath $tempVarPath -Encoding UTF8
        
        Write-Host "[INFO] Starting configuration..." -ForegroundColor Cyan
        $configStart = Get-Date
        
        & $autoDeployPath -varPath $tempVarPath
        
        $configDuration = (Get-Date) - $configStart
        Write-Host "`n[SUCCESS] Configured in $($configDuration.ToString('mm\:ss'))" -ForegroundColor Green
        
        $successCount++
        $results += @{
            ApplianceName = $applianceName
            Status = "Success"
            Duration = $configDuration
            IP = if ($settings.UseStaticIP) { $settings.StaticIP } else { $privateIp }
        }
        
        Remove-Item $tempVarPath -Force
        
    }
    catch {
        Write-Host "`n[FAILED] $($_.Exception.Message)" -ForegroundColor Red
        
        $failureCount++
        $results += @{
            ApplianceName = $applianceName
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
}

# Generate summary
Write-Host "`n[STEP 7] Generating summary..." -ForegroundColor Yellow

$totalDuration = (Get-Date) - $scriptStartTime
$summaryPath = Join-Path $scriptDir "deployment-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

$summary = @"
NASUNI DEPLOYMENT SUMMARY
=========================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Duration: $($totalDuration.ToString('hh\:mm\:ss'))
Workspace: $currentWorkspace

RESULTS
-------
Total: $($results.Count)
Success: $successCount
Failed: $failureCount

APPLIANCES
----------
$($results | ForEach-Object {
    $status = if ($_.Status -eq "Success") { "✓" } else { "✗" }
    "$status $($_.ApplianceName) - $($_.Status)"
    if ($_.IP) { "  IP: $($_.IP)" }
    if ($_.Error) { "  Error: $($_.Error)" }
} | Out-String)

NEXT STEPS
----------
1. Log in to NMC: https://$NmcHostname
2. Verify appliances show as Online
3. Create volumes and shares
4. Configure user access

"@

$summary | Out-File -FilePath $summaryPath -Encoding UTF8
Write-Host "[OK] Summary: $summaryPath" -ForegroundColor Green
Write-Host "`n$summary" -ForegroundColor Cyan

Write-Host @"

╔════════════════════════════════════════════════════════════════════════╗
║    $(if ($failureCount -eq 0) { "✓ COMPLETE" } else { "⚠ COMPLETE WITH ERRORS" })                                                    ║
║    Success: $successCount/$($results.Count)                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Yellow" })

exit $(if ($failureCount -eq 0) { 0 } else { 1 })