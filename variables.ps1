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
$NmcHostname = "qcoscujnunicp01.quantaservices.local"
$NmcUsername = "svcqconasuni"
$NmcPassword = '!!!l0c4dm1n!!!3c905btx!!!'

# ----------------------------------------------------------------------------
# SERIAL NUMBER RETRIEVAL
# ----------------------------------------------------------------------------
# "nmc" - Retrieve from NMC (recommended, works with all Nasuni versions)
$SerialNumberMethod = "nmc"

# ----------------------------------------------------------------------------
# DEFAULT NETWORK SETTINGS
# ----------------------------------------------------------------------------
# These are fallback values if VNet DNS cannot be detected
# Leave empty to auto-detect from VNet configuration
$DefaultPrimaryDns = ''         # Empty = Auto-detect from VNet
$DefaultSecondaryDns = ''       # Empty = Auto-detect from VNet
$DefaultSearchDomain = 'quantaservices.com'
$DefaultNtpServer = 'time.windows.com'
$DefaultNtpServer2 = 'pool.ntp.org'

# Manual DNS Override (optional)
# If you want to force specific DNS servers instead of auto-detection, uncomment and configure:
$ManualDnsOverride = @{
    # Example - uncomment and update if needed:
    # "PGR-Nasuni-Network-pd-scus-vnet" = @("10.239.0.10", "10.239.0.11")
    # "QIS-Nasuni-Network-pd-scus-vnet" = @("10.240.0.10", "10.240.0.11")
    # "QTI-Nasuni-Network-pd-cace-vnet" = @("10.241.0.10", "10.241.0.11")
}

# ----------------------------------------------------------------------------
# APPLIANCE-SPECIFIC OVERRIDES
# ----------------------------------------------------------------------------
# Using DHCP for all appliances - IPs assigned by Azure automatically
# DNS will be auto-detected from VNet configuration per region
$ApplianceOverrides = @{
    "PGRSCUTNUNIVP01" = @{
        # Network Configuration - DHCP
        UseStaticIP = $false  # Let Azure assign IP via DHCP
        # PrimaryDns and SecondaryDns will be auto-detected from VNet
        SearchDomain = "quantaservices.com"
        
        # Active Directory (optional)
        JoinAD = $false
        AdDomain = "quantaservices.com"
        AdUsername = "svc-nasuni"
        AdPassword = "YourADPassword123!"  # UPDATE if using AD
        AdOU = ""
        
        # Description
        Description = "PGR Production Nasuni - Houston"
        Timezone = "America/Chicago"
    }
    
    "QISSCUTNUNIVP01" = @{
        # Network Configuration - DHCP
        UseStaticIP = $false  # Let Azure assign IP via DHCP
        # PrimaryDns and SecondaryDns will be auto-detected from VNet
        SearchDomain = "quantaservices.com"
        
        # Active Directory
        JoinAD = $false
        AdDomain = "quantaservices.com"
        AdUsername = "svc-nasuni"
        AdPassword = "YourADPassword123!"  # UPDATE if using AD
        
        Description = "QIS Production Nasuni - Houston"
        Timezone = "America/Chicago"
    }
    
    "QTICCETNUNIVP01" = @{
        # Network Configuration - DHCP
        UseStaticIP = $false  # Let Azure assign IP via DHCP
        # PrimaryDns and SecondaryDns will be auto-detected from VNet
        SearchDomain = "quantaservices.com"
        
        # Active Directory
        JoinAD = $false
        AdDomain = "quantaservices.com"
        AdUsername = "svc-nasuni"
        AdPassword = "YourADPassword123!"  # UPDATE if using AD
        
        Description = "QTI Production Nasuni - Canada"
        Timezone = "America/Toronto"
    }
}

# ----------------------------------------------------------------------------
# DEFAULT SETTINGS (Used if not overridden above)
# ----------------------------------------------------------------------------
$DefaultSettings = @{
    UseStaticIP = $false  # Default to DHCP
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
# Leave empty - script will auto-retrieve from Azure after Terraform creates them
$StorageAccountKeys = @{
    "pgrscusnasunipdst" = ""  # Auto-retrieve from Azure
    "qisscusnasunipdst" = ""  # Auto-retrieve from Azure
    "qticcesnasunipdad" = ""  # Auto-retrieve from Azure
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

function Get-VNetDnsServers {
    <#
    .SYNOPSIS
    Retrieves DNS servers configured on an Azure VNet
    
    .DESCRIPTION
    Queries Azure to get the DNS server configuration for a specific VNet.
    If no custom DNS is configured, returns Azure's default DNS (168.63.129.16)
    
    .PARAMETER VNetName
    Name of the Virtual Network
    
    .PARAMETER ResourceGroup
    Resource Group containing the VNet
    
    .PARAMETER SubscriptionId
    Azure Subscription ID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$VNetName,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId
    )
    
    try {
        Write-Host "[INFO] Retrieving DNS servers from VNet: $VNetName" -ForegroundColor Cyan
        
        # Set subscription context
        az account set --subscription $SubscriptionId 2>$null | Out-Null
        
        # Get VNet DNS configuration
        $dnsServersJson = az network vnet show `
            --name $VNetName `
            --resource-group $ResourceGroup `
            --query "dhcpOptions.dnsServers" `
            -o json 2>$null
        
        if ($dnsServersJson) {
            $dnsServers = $dnsServersJson | ConvertFrom-Json
            
            if ($dnsServers -and $dnsServers.Count -gt 0) {
                Write-Host "[OK] Found DNS servers in VNet: $($dnsServers -join ', ')" -ForegroundColor Green
                return $dnsServers
            }
        }
        
        # If no custom DNS, VNet uses Azure default DNS (168.63.129.16)
        Write-Host "[INFO] VNet uses Azure default DNS (168.63.129.16)" -ForegroundColor Cyan
        return @("168.63.129.16")
    }
    catch {
        Write-Warning "Could not retrieve DNS from VNet $VNetName : $_"
        return @()
    }
}

function Get-ApplianceSettings {
    <#
    .SYNOPSIS
    Gets configuration settings for a specific appliance
    
    .DESCRIPTION
    Merges default settings with CSV data and appliance-specific overrides.
    Automatically detects DNS from VNet configuration if not explicitly set.
    
    .PARAMETER ApplianceName
    Name of the appliance (VM name)
    
    .PARAMETER CsvData
    Hashtable containing data from the CSV row for this appliance
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApplianceName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$CsvData
    )
    
    $settings = $DefaultSettings.Clone()
    
    # Merge CSV data
    foreach ($key in $CsvData.Keys) {
        $settings[$key] = $CsvData[$key]
    }
    
    # Apply appliance-specific overrides
    if ($ApplianceOverrides.ContainsKey($ApplianceName)) {
        $override = $ApplianceOverrides[$ApplianceName]
        foreach ($key in $override.Keys) {
            $settings[$key] = $override[$key]
        }
    }
    
    # Auto-detect DNS from VNet if not explicitly set
    $needsDnsDetection = (-not $settings.ContainsKey('PrimaryDns') -or [string]::IsNullOrEmpty($settings.PrimaryDns))
    
    if ($needsDnsDetection -and $CsvData.ContainsKey('existing_vnet_name') -and $CsvData.ContainsKey('existing_vnet_resource_group')) {
        $vnetName = $CsvData.existing_vnet_name
        $vnetRg = $CsvData.existing_vnet_resource_group
        $subId = $CsvData.subscription_id
        
        # Check for manual override first
        if ($ManualDnsOverride.ContainsKey($vnetName)) {
            $dnsServers = $ManualDnsOverride[$vnetName]
            Write-Host "[INFO] Using manual DNS override for $vnetName" -ForegroundColor Cyan
        }
        else {
            # Auto-detect from VNet
            $dnsServers = Get-VNetDnsServers -VNetName $vnetName -ResourceGroup $vnetRg -SubscriptionId $subId
        }
        
        if ($dnsServers -and $dnsServers.Count -gt 0) {
            $settings.PrimaryDns = $dnsServers[0]
            if ($dnsServers.Count -gt 1) {
                $settings.SecondaryDns = $dnsServers[1]
            }
            else {
                # If only one DNS server, use it for both
                $settings.SecondaryDns = $dnsServers[0]
            }
            
            Write-Host "[OK] DNS configured: Primary=$($settings.PrimaryDns), Secondary=$($settings.SecondaryDns)" -ForegroundColor Green
        }
    }
    
    # Fallback to defaults if still not set
    if (-not $settings.ContainsKey('PrimaryDns') -or [string]::IsNullOrEmpty($settings.PrimaryDns)) {
        if (-not [string]::IsNullOrEmpty($DefaultPrimaryDns)) {
            $settings.PrimaryDns = $DefaultPrimaryDns
            Write-Host "[INFO] Using default primary DNS: $DefaultPrimaryDns" -ForegroundColor Cyan
        }
        else {
            Write-Warning "No DNS configured and auto-detection failed. Using Azure default DNS."
            $settings.PrimaryDns = "168.63.129.16"
        }
    }
    
    if (-not $settings.ContainsKey('SecondaryDns') -or [string]::IsNullOrEmpty($settings.SecondaryDns)) {
        if (-not [string]::IsNullOrEmpty($DefaultSecondaryDns)) {
            $settings.SecondaryDns = $DefaultSecondaryDns
        }
        else {
            $settings.SecondaryDns = $settings.PrimaryDns
        }
    }
    
    if (-not $settings.ContainsKey('SearchDomain') -or [string]::IsNullOrEmpty($settings.SearchDomain)) {
        $settings.SearchDomain = $DefaultSearchDomain
    }
    
    return $settings
}

function Get-StorageAccountKey {
    <#
    .SYNOPSIS
    Retrieves Azure Storage Account access key
    
    .DESCRIPTION
    First checks if key is in $StorageAccountKeys hashtable.
    If not found, automatically retrieves from Azure using Azure CLI.
    
    .PARAMETER StorageAccountName
    Name of the Azure Storage Account
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName
    )
    
    # First check if we have it in the hashtable
    if ($StorageAccountKeys.ContainsKey($StorageAccountName)) {
        $key = $StorageAccountKeys[$StorageAccountName]
        if (-not [string]::IsNullOrEmpty($key)) {
            return $key
        }
    }
    
    # If not, retrieve from Azure
    try {
        Write-Host "[INFO] Retrieving storage key for $StorageAccountName from Azure..." -ForegroundColor Cyan
        $key = az storage account keys list --account-name $StorageAccountName --query "[0].value" -o tsv 2>$null
        if ($key) {
            Write-Host "[OK] Retrieved storage key from Azure" -ForegroundColor Green
            return $key
        }
    }
    catch {
        Write-Warning "Could not retrieve storage key for $StorageAccountName: $_"
    }
    
    throw "Could not retrieve storage key for $StorageAccountName. Ensure storage account exists and you have access."
}

function Test-Configuration {
    <#
    .SYNOPSIS
    Validates the configuration in this file
    
    .DESCRIPTION
    Checks for common configuration issues before deployment
    #>
    Write-Host "Validating configuration..." -ForegroundColor Cyan
    
    $issues = @()
    
    if (-not (Test-Path $AppliancesCsvPath)) {
        $issues += "CSV file not found: $AppliancesCsvPath"
    }
    
    if ($SerialNumberMethod -eq "nmc") {
        if ($NmcHostname -like "*example*" -or $NmcHostname -like "*your-nmc*") {
            $issues += "NMC Hostname needs to be updated with actual hostname"
        }
        if ($NmcPassword -like "*YourNmc*" -or $NmcPassword -like "*example*") {
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
        Write-Host "Network: Using DHCP for IP assignment" -ForegroundColor Cyan
        Write-Host "DNS: Auto-detection from VNet enabled" -ForegroundColor Cyan
        Write-Host "Storage Keys: Auto-retrieval from Azure enabled" -ForegroundColor Cyan
        return $true
    }
}

# ============================================================================
# NOTES AND USAGE
# ============================================================================
# 
# CONFIGURATION SUMMARY:
# - IP Assignment: DHCP (automatic from Azure)
# - DNS Servers: Auto-detected from VNet configuration per region
# - Storage Keys: Auto-retrieved from Azure after Terraform deployment
# - NMC: qcoscujnunicp01.quantaservices.local
#
# BEFORE RUNNING:
# 1. Ensure NMC (qcoscujnunicp01.quantaservices.local) is accessible
# 2. Verify you're logged into Azure with: az login
# 3. Deploy infrastructure first with Terraform
# 4. Run this automation script after Terraform completes
#
# USAGE EXAMPLES:
# 
# Configure appliances in current workspace:
#   pwsh Deploy-NasuniAutomation.ps1 -Workspace pgr
#
# Configure all appliances across all subscriptions:
#   pwsh Deploy-NasuniAutomation.ps1 -Mode all
#
# Configure specific appliances:
#   pwsh Deploy-NasuniAutomation.ps1 -Mode specific -Appliances "PGRSCUTNUNIVP01"
#
# Dry run (test without configuring):
#   pwsh Deploy-NasuniAutomation.ps1 -Workspace pgr -DryRun
#
# WHAT GETS AUTO-CONFIGURED:
# - Private IP addresses (from Terraform outputs)
# - DNS servers (from VNet configuration)
# - Storage account keys (from Azure)
# - Region-specific settings (timezone, location)
#
# MANUAL OVERRIDES (if needed):
# - Set $ManualDnsOverride for specific VNets
# - Set $DefaultPrimaryDns/$DefaultSecondaryDns as fallback
# - Update $ApplianceOverrides for appliance-specific settings
# ============================================================================