# ============================================================================
# Nasuni Edge Appliance Automation Variables Configuration
# Multi-Subscription Workspace Integration
# ============================================================================
# Copy this file to your Terraform directory and update the values below
# Usage: ./Deploy-NasuniAutomation.ps1 -Workspace <workspace-name>
# ============================================================================

# ----------------------------------------------------------------------------
# DEPLOYMENT MODE
# ----------------------------------------------------------------------------
# "workspace" - Configure appliances in current Terraform workspace (recommended)
# "all"       - Configure all appliances from CSV regardless of workspace
# "specific"  - Configure only specific appliances (set $TargetAppliances)
$DeploymentMode = "workspace"

# If DeploymentMode = "specific", list appliance names here
$TargetAppliances = @()

# ----------------------------------------------------------------------------
# CSV FILE PATH
# ----------------------------------------------------------------------------
$AppliancesCsvPath = "./appliances.csv"

# ----------------------------------------------------------------------------
# NMC (NASUNI MANAGEMENT CONSOLE) CONFIGURATION
# ----------------------------------------------------------------------------
# REQUIRED: Update these with your actual NMC details
$NmcHostname = "qcoscujnunicp01.quantaservices.local"  # UPDATE: Your NMC hostname
$NmcUsername = "svcqconasuni"                    # UPDATE: Your NMC admin username
$NmcPassword = '!!!l0c4dm1n!!!3c905btx!!!'      # UPDATE: Your NMC password (use single quotes)

# ----------------------------------------------------------------------------
# SERIAL NUMBER RETRIEVAL
# ----------------------------------------------------------------------------
# "nmc" - Retrieve from NMC (recommended, works with all Nasuni versions)
$SerialNumberMethod = "nmc"

# ----------------------------------------------------------------------------
# DEFAULT NETWORK SETTINGS
# ----------------------------------------------------------------------------
# These are used if not overridden in $ApplianceOverrides
$DefaultPrimaryDns = '10.0.0.10'        # UPDATE: Your DNS server
$DefaultSecondaryDns = '10.0.0.11'      # UPDATE: Your secondary DNS
$DefaultSearchDomain = 'quantaservices.com'
$DefaultNtpServer = 'time.windows.com'
$DefaultNtpServer2 = 'pool.ntp.org'

# ----------------------------------------------------------------------------
# APPLIANCE-SPECIFIC OVERRIDES
# ----------------------------------------------------------------------------
# Configure each appliance with specific network settings
# REQUIRED: Update with your actual network details
$ApplianceOverrides = @{
    "PGRSCUTNUNIVP01" = @{
        # Network Configuration
        UseStaticIP = $true
        StaticIP = "10.239.4.10"              # UPDATE: Your static IP
        Netmask = "255.255.255.0"             # UPDATE: Your netmask
        Gateway = "10.239.4.1"                # UPDATE: Your gateway
        PrimaryDns = "10.0.0.10"              # UPDATE: Your DNS
        SecondaryDns = "10.0.0.11"            # UPDATE: Your DNS
        SearchDomain = "quantaservices.com"
        
        # Active Directory (optional)
        JoinAD = $false                        # Set to $true if joining AD
        AdDomain = "quantaservices.com"
        AdUsername = "svc-nasuni"              # UPDATE: Your AD service account
        AdPassword = "YourADPassword123!"      # UPDATE: Your AD password
        AdOU = ""                              # Optional: OU path
        
        # Description
        Description = "PGR Production Nasuni - Houston"
        Timezone = "America/Chicago"
    }
    
    "QISSCUTNUNIVP01" = @{
        # Network Configuration
        UseStaticIP = $true
        StaticIP = "10.240.4.10"              # UPDATE: Your static IP
        Netmask = "255.255.255.0"
        Gateway = "10.240.4.1"                # UPDATE: Your gateway
        PrimaryDns = "10.0.0.10"
        SecondaryDns = "10.0.0.11"
        SearchDomain = "quantaservices.com"
        
        # Active Directory
        JoinAD = $false
        AdDomain = "quantaservices.com"
        AdUsername = "svc-nasuni"
        AdPassword = "YourADPassword123!"
        
        Description = "QIS Production Nasuni - Houston"
        Timezone = "America/Chicago"
    }
    
    "QTICCETNUNIVP01" = @{
        # Network Configuration
        UseStaticIP = $true
        StaticIP = "10.241.4.10"              # UPDATE: Your static IP
        Netmask = "255.255.255.0"
        Gateway = "10.241.4.1"                # UPDATE: Your gateway
        PrimaryDns = "10.0.0.20"              # UPDATE: Canada DNS
        SecondaryDns = "10.0.0.21"
        SearchDomain = "quantaservices.com"
        
        # Active Directory
        JoinAD = $false
        AdDomain = "quantaservices.com"
        AdUsername = "svc-nasuni"
        AdPassword = "YourADPassword123!"
        
        Description = "QTI Production Nasuni - Canada"
        Timezone = "America/Toronto"           # Canada timezone
    }
}

# ----------------------------------------------------------------------------
# DEFAULT SETTINGS (Used if not overridden above)
# ----------------------------------------------------------------------------
$DefaultSettings = @{
    UseStaticIP = $false
    Timezone = 'America/Chicago'
    Mtu = '1500'
    JoinAD = $false
    EnableSnmp = $false
    SnmpVersion = 'v3'
    SnmpUsername = 'snmpadmin'
    SnmpPassword = 'SnmpSecure123!'
    SnmpAuthProtocol = 'SHA'
    EnableEmail = $false
    SmtpServer = 'smtp.quantaservices.com'
    SmtpPort = '25'
    SmtpFromAddress = 'nasuni-alerts@quantaservices.com'
    SmtpToAddress = 'cwilliford@quantaservices.com'
    SmtpUseTls = $false
    CreateInitialVolume = $false
    VolumeProtocol = 'CIFS'
}

# ----------------------------------------------------------------------------
# AZURE STORAGE ACCOUNT KEYS
# ----------------------------------------------------------------------------
# REQUIRED: Get these from Azure Portal or Azure CLI
# az storage account keys list --account-name <name> --query "[0].value" -o tsv
$StorageAccountKeys = @{
    "pgrscusnasunipdst" = ""  # UPDATE: Paste key from Azure
    "qisscusnasunipdst" = ""  # UPDATE: Paste key from Azure
    "qticcesnasunipdad" = ""  # UPDATE: Paste key from Azure
}

# Default container naming pattern
$DefaultContainerPattern = "nasuni-{environment}-volume"

# ----------------------------------------------------------------------------
# AUTOMATION BEHAVIOR
# ----------------------------------------------------------------------------
$AcceptEula = $true
$SkipUpdates = $true
$ConfigStepDelay = 10
$MaxRetries = 3
$VerboseLogging = $true
$ErrorActionPreference = "Stop"

# Parallel execution (use with caution)
$UseParallelExecution = $false
$MaxParallelJobs = 3

# ----------------------------------------------------------------------------
# WORKSPACE TO SUBSCRIPTION MAPPING
# ----------------------------------------------------------------------------
# MUST match your locals.tf workspace_subscriptions
$WorkspaceSubscriptions = @{
    "pgr" = "c7a18a12-7088-4955-8504-5156e8f48fdd"
    "qis" = "6b025554-fc3d-49a6-a9a1-56d397909042"
    "qti" = "8f054358-9640-4873-a3bf-f1e3547ed39f"
}

# Friendly names for reporting
$SubscriptionNames = @{
    "c7a18a12-7088-4955-8504-5156e8f48fdd" = "PGR"
    "6b025554-fc3d-49a6-a9a1-56d397909042" = "QIS"
    "8f054358-9640-4873-a3bf-f1e3547ed39f" = "QTI"
}

# ----------------------------------------------------------------------------
# REPORTING
# ----------------------------------------------------------------------------
$GenerateReport = $true
$SendCompletionEmail = $false
$SendErrorEmail = $false

# ----------------------------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------------------------

function Get-ApplianceSettings {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApplianceName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$CsvData
    )
    
    $settings = $DefaultSettings.Clone()
    
    foreach ($key in $CsvData.Keys) {
        $settings[$key] = $CsvData[$key]
    }
    
    if ($ApplianceOverrides.ContainsKey($ApplianceName)) {
        $override = $ApplianceOverrides[$ApplianceName]
        foreach ($key in $override.Keys) {
            $settings[$key] = $override[$key]
        }
    }
    
    if (-not $settings.ContainsKey('PrimaryDns') -or [string]::IsNullOrEmpty($settings.PrimaryDns)) {
        $settings.PrimaryDns = $DefaultPrimaryDns
    }
    if (-not $settings.ContainsKey('SecondaryDns') -or [string]::IsNullOrEmpty($settings.SecondaryDns)) {
        $settings.SecondaryDns = $DefaultSecondaryDns
    }
    if (-not $settings.ContainsKey('SearchDomain') -or [string]::IsNullOrEmpty($settings.SearchDomain)) {
        $settings.SearchDomain = $DefaultSearchDomain
    }
    
    return $settings
}

function Get-StorageAccountKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName
    )
    
    if ($StorageAccountKeys.ContainsKey($StorageAccountName)) {
        $key = $StorageAccountKeys[$StorageAccountName]
        if (-not [string]::IsNullOrEmpty($key)) {
            return $key
        }
    }
    
    try {
        Write-Host "[INFO] Retrieving storage key for $StorageAccountName from Azure..." -ForegroundColor Cyan
        $key = az storage account keys list --account-name $StorageAccountName --query "[0].value" -o tsv 2>$null
        if ($key) {
            return $key
        }
    }
    catch {
        Write-Warning "Could not retrieve storage key for $StorageAccountName"
    }
    
    return ""
}

function Test-Configuration {
    Write-Host "Validating configuration..." -ForegroundColor Cyan
    
    $issues = @()
    
    if (-not (Test-Path $AppliancesCsvPath)) {
        $issues += "CSV file not found: $AppliancesCsvPath"
    }
    
    if ($SerialNumberMethod -eq "nmc") {
        if ($NmcHostname -eq "nmc.quantaservices.com") {
            $issues += "NMC Hostname needs to be updated with actual hostname"
        }
        if ($NmcPassword -like "*YourNmc*") {
            $issues += "NMC Password needs to be updated"
        }
    }
    
    if ($DeploymentMode -eq "specific" -and $TargetAppliances.Count -eq 0) {
        $issues += "DeploymentMode is 'specific' but no appliances in TargetAppliances"
    }
    
    $terraformWorkspaces = @("pgr", "qis", "qti")
    foreach ($ws in $terraformWorkspaces) {
        if (-not $WorkspaceSubscriptions.ContainsKey($ws)) {
            $issues += "Terraform workspace '$ws' not in WorkspaceSubscriptions mapping"
        }
    }
    
    $allKeysEmpty = $true
    foreach ($key in $StorageAccountKeys.Values) {
        if (-not [string]::IsNullOrEmpty($key)) {
            $allKeysEmpty = $false
            break
        }
    }
    if ($allKeysEmpty) {
        $issues += "All storage account keys are empty. Update StorageAccountKeys or ensure Azure CLI access."
    }
    
    if ($ApplianceOverrides.Count -gt 0) {
        foreach ($applianceName in $ApplianceOverrides.Keys) {
            $override = $ApplianceOverrides[$applianceName]
            if ($override.UseStaticIP) {
                if ([string]::IsNullOrEmpty($override.StaticIP)) {
                    $issues += "Appliance '$applianceName' has UseStaticIP=true but no StaticIP"
                }
                if ([string]::IsNullOrEmpty($override.Gateway)) {
                    $issues += "Appliance '$applianceName' has UseStaticIP=true but no Gateway"
                }
            }
            if ($override.JoinAD) {
                if ([string]::IsNullOrEmpty($override.AdUsername) -or [string]::IsNullOrEmpty($override.AdPassword)) {
                    $issues += "Appliance '$applianceName' has JoinAD=true but missing AD credentials"
                }
            }
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-Host "`nConfiguration Issues:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
        Write-Host "`nPlease update Variables.ps1 before proceeding.`n" -ForegroundColor Yellow
        return $false
    }
    else {
        Write-Host "Configuration validation passed!" -ForegroundColor Green
        Write-Host "Mode: $DeploymentMode" -ForegroundColor Cyan
        Write-Host "CSV: $AppliancesCsvPath" -ForegroundColor Cyan
        Write-Host "Workspaces: $($WorkspaceSubscriptions.Count) configured" -ForegroundColor Cyan
        return $true
    }
}

# ============================================================================
# NOTES
# ============================================================================
<#
BEFORE RUNNING:
1. Update NMC hostname, username, and password
2. Get storage account keys from Azure and add to $StorageAccountKeys
3. Configure $ApplianceOverrides with your network settings
4. Set static IPs, gateways, DNS for each appliance
5. Configure Active Directory settings if joining domain
6. Verify workspace mapping matches locals.tf
7. Ensure VPN/network access to appliances

USAGE:
# Configure appliances in current workspace
pwsh Deploy-NasuniAutomation.ps1 -Workspace pgr

# Configure all appliances
pwsh Deploy-NasuniAutomation.ps1 -Mode all

# Configure specific appliances
pwsh Deploy-NasuniAutomation.ps1 -Mode specific -Appliances "PGRSCUTNUNIVP01"

# Dry run (test without configuring)
pwsh Deploy-NasuniAutomation.ps1 -Workspace pgr -DryRun
#>