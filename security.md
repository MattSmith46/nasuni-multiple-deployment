# Security Guidelines

## Critical Security Requirements

### 1. Credential Management

#### ❌ NEVER Do This:
- Commit `terraform.tfvars` with passwords
- Commit `.env` files with credentials
- Commit state files (`.tfstate`, `.tfstate.backup`)
- Share passwords in plain text via email/chat
- Use weak passwords (< 12 characters)

#### ✅ ALWAYS Do This:
- Use environment variables for credentials
- Use Azure Key Vault for production passwords
- Rotate credentials regularly (every 90 days minimum)
- Use strong passwords (12+ chars, mixed case, numbers, symbols)
- Enable MFA on all Azure accounts

### 2. Network Security

#### Current NSG Configuration:
```hcl
source_address_prefix = "VirtualNetwork"  # Allows traffic from VNet only
```

#### Recommended Additional Hardening:
1. **Use Specific IP Ranges:**
   ```hcl
   source_address_prefix = "10.239.0.0/16"  # Your VNet CIDR
   ```

2. **Use Network Security Groups Per Subnet:**
   - Create subnet-specific NSGs
   - Implement least privilege access
   - Document all exceptions

3. **Enable Azure Firewall:**
   - Centralized traffic inspection
   - Advanced threat protection
   - Logging and monitoring

4. **Use Azure Private Link:**
   - Private connectivity to storage accounts
   - No public internet exposure
   - Traffic stays on Microsoft backbone

### 3. State File Security

#### State files contain sensitive data:
- Resource IDs
- Private IP addresses
- Configuration details
- Potentially credentials (if not using sensitive = true)

#### Protection Measures:

**Local State (Current):**
```bash
# Verify .gitignore includes:
*.tfstate
*.tfstate.*
*.tfstate.backup
```

**Remote State (Recommended for Production):**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate<uniqueid>"
    container_name       = "tfstate"
    key                  = "nasuni.tfstate"
    
    # Enable encryption
    use_msi              = true
  }
}
```

**State File Encryption:**
- Enable encryption at rest on storage account
- Use customer-managed keys (CMK) if required
- Enable soft delete and versioning
- Implement RBAC for state access

### 4. Azure Key Vault Integration

#### Setup:
```bash
# Create Key Vault
az keyvault create \
  --name "nasuni-kv-${RANDOM}" \
  --resource-group "security-rg" \
  --location "southcentralus"

# Store admin password
az keyvault secret set \
  --vault-name "nasuni-kv-${RANDOM}" \
  --name "nasuni-admin-password" \
  --value "YourSecurePassword123!"
```

#### Terraform Integration:
```hcl
data "azurerm_key_vault" "nasuni" {
  name                = "nasuni-kv-12345"
  resource_group_name = "security-rg"
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "nasuni-admin-password"
  key_vault_id = data.azurerm_key_vault.nasuni.id
}

# Use in module
admin_password = data.azurerm_key_vault_secret.admin_password.value
```

### 5. Audit and Monitoring

#### Enable Azure Activity Logs:
```bash
# Enable for subscription
az monitor log-profiles create \
  --name "nasuni-audit" \
  --location "global" \
  --locations "southcentralus" "canadacentral" \
  --categories "Write" "Delete" "Action"
```

#### Enable Diagnostic Settings:
```hcl
resource "azurerm_monitor_diagnostic_setting" "nasuni" {
  name               = "nasuni-diagnostics"
  target_resource_id = azurerm_linux_virtual_machine.nasuni.id
  storage_account_id = azurerm_storage_account.logs.id

  log {
    category = "Administrative"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

#### Monitor for:
- Failed login attempts
- Configuration changes
- Network security group modifications
- Resource deletions
- Unusual traffic patterns

### 6. RBAC (Role-Based Access Control)

#### Principle of Least Privilege:

**For Terraform Service Principal:**
```bash
# Create service principal with limited scope
az ad sp create-for-rbac \
  --name "terraform-nasuni" \
  --role "Contributor" \
  --scopes /subscriptions/{sub-id}/resourceGroups/nasuni-rg
```

**Recommended Roles:**
- `Virtual Machine Contributor` - VM operations only
- `Network Contributor` - Network operations only
- `Storage Account Contributor` - Storage operations only

**Avoid:**
- `Owner` role (too broad)
- `Contributor` at subscription level (too broad)

### 7. Compliance

#### Required Tags:
- `critical-infrastructure`: Yes/No
- `external-facing`: Yes/No
- `regulatory-data`: Yes/No
- `owner`: Email address
- `environment`: PD/NP/DR

#### Data Classification:
- Ensure regulatory-data tag is accurate
- Implement additional controls for regulated data
- Document compliance requirements

### 8. Vulnerability Management

#### Keep Updated:
```bash
# Update Terraform
terraform version
# If outdated, download latest

# Update Azure CLI
az upgrade

# Update Nasuni appliances
# Follow Nasuni's update procedures
```

#### Regular Security Scans:
```bash
# Use tools like:
- Checkov (Terraform security scanning)
- tfsec (Terraform static analysis)
- Azure Security Center recommendations
```

### 9. Incident Response

#### In Case of Suspected Compromise:

1. **Immediate Actions:**
   - Rotate all passwords immediately
   - Review Azure Activity Logs
   - Check for unauthorized resource modifications
   - Isolate affected resources (NSG rules)

2. **Investigation:**
   - Review state file for tampering
   - Check git history for unauthorized commits
   - Review Azure AD sign-in logs
   - Check for new service principals

3. **Recovery:**
   - Restore from known good state
   - Re-deploy with new credentials
   - Document lessons learned
   - Update security procedures

### 10. Pre-Deployment Checklist

Before running `terraform apply`:

- [ ] Reviewed all code changes
- [ ] Validated CSV configuration
- [ ] Verified no sensitive data in code
- [ ] Checked NSG rules are appropriate
- [ ] Confirmed backup/disaster recovery plan
- [ ] Tested in non-production first
- [ ] Got necessary approvals
- [ ] Documented changes