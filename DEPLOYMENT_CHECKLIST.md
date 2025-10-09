# Deployment Checklist

Use this checklist before deploying to production.

## Pre-Deployment (Required)

### 1. Prerequisites
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform >= 1.0 installed (`terraform version`)
- [ ] Access to all required Azure subscriptions verified (`./scripts/verify-subscriptions.sh`)
- [ ] Git repository initialized and clean working directory

### 2. Configuration Files
- [ ] Created `terraform.tfvars` from `terraform.tfvars.example`
- [ ] Created `appliances.csv` from `appliances.csv.example`
- [ ] Reviewed and updated `locals.tf` workspace_subscriptions mapping
- [ ] Verified all subscription IDs are correct
- [ ] **Critical**: Verified `terraform.tfvars` is in `.gitignore`
- [ ] **Critical**: Verified state files are in `.gitignore`

### 3. CSV Validation
- [ ] CSV has exactly 20 columns
- [ ] All VM names are unique
- [ ] All subscription IDs are valid GUIDs
- [ ] All resource group names follow naming convention
- [ ] All VNet/Subnet names exist in Azure
- [ ] All required tags are populated
- [ ] Owner emails are valid
- [ ] Ran validation script: `./scripts/validate-csv.sh`

### 4. Security Review
- [ ] Changed default admin password
- [ ] Password is 12+ characters with complexity
- [ ] Considered using environment variables for password
- [ ] Reviewed NSG rules (currently set to `VirtualNetwork`)
- [ ] Decided if further NSG hardening needed (specific IP ranges)
- [ ] Reviewed audit logging requirements
- [ ] Documented security exceptions (if any)

### 5. Azure Prerequisites
- [ ] All resource groups exist (or run `./scripts/create-resource-groups.sh`)
- [ ] All VNets exist in correct subscriptions
- [ ] All subnets exist with correct CIDR ranges
- [ ] Storage accounts created (if specified in CSV)
- [ ] RBAC permissions granted to deployment account
- [ ] Marketplace terms accepted (will be automated, but verify access)

### 6. Terraform Initialization
- [ ] Ran `terraform init` successfully
- [ ] Reviewed `.terraform.lock.hcl` (optional: commit for version locking)
- [ ] Workspace strategy understood (one workspace per subscription)
- [ ] Default workspace mapped correctly in `locals.tf`

## Deployment (Per Subscription)

### For Each Workspace (pgr, qis, qti):

#### Planning Phase
- [ ] Selected workspace: `terraform workspace select <workspace>`
- [ ] Verified workspace: `terraform workspace show`
- [ ] Ran `terraform plan`
- [ ] Reviewed plan output for accuracy
- [ ] Verified correct number of resources to create
- [ ] No unexpected resource deletions
- [ ] Saved plan: `terraform plan -out=<workspace>.tfplan`
- [ ] Had plan reviewed by second team member (recommended)

#### Approval Phase
- [ ] Got approval from change management (if required)
- [ ] Scheduled maintenance window (if required)
- [ ] Notified stakeholders of deployment
- [ ] Backup existing infrastructure state (if updating)

#### Execution Phase
- [ ] Ran `terraform apply <workspace>.tfplan`
- [ ] Monitored apply progress for errors
- [ ] Verified all resources created successfully
- [ ] Checked Azure Portal to confirm resources exist
- [ ] Tested connectivity to deployed VMs (if accessible)

#### Verification Phase
- [ ] Ran `terraform output nasuni_appliances`
- [ ] Verified all expected outputs present
- [ ] Checked VM status in Azure Portal (Running)
- [ ] Verified private IPs assigned correctly
- [ ] Confirmed NSG rules applied
- [ ] Verified disk attachment (cache disk)
- [ ] Checked tags on all resources
- [ ] Tested Nasuni console access (via VPN/jump box): `https://<private-ip>:8443`

#### Documentation Phase
- [ ] Documented deployment date and time
- [ ] Recorded any issues encountered
- [ ] Updated inventory/CMDB
- [ ] Saved terraform outputs to documentation
- [ ] Cleaned up plan file: `rm <workspace>.tfplan`

## Post-Deployment (All Subscriptions)

### 1. Validation
- [ ] All workspaces deployed successfully
- [ ] Ran summary check across all workspaces
- [ ] Verified `terraform output all_subscriptions_summary`
- [ ] Total appliance count matches CSV
- [ ] No orphaned resources in any subscription

### 2. Security Hardening
- [ ] Reviewed NSG rules in Azure Portal
- [ ] Enabled Azure Security Center recommendations
- [ ] Configured diagnostic settings on VMs
- [ ] Enabled Azure Monitor alerts
- [ ] Verified no public IPs created
- [ ] Confirmed boot diagnostics configured
- [ ] Reviewed Azure Activity Logs

### 3. Backup & DR
- [ ] Documented state file location
- [ ] Backed up state files (if using local state)
- [ ] Configured Azure Backup (if required)
- [ ] Tested disaster recovery procedure
- [ ] Documented rollback procedure

### 4. Monitoring Setup
- [ ] Configured VM monitoring
- [ ] Set up alert rules for:
  - [ ] VM availability
  - [ ] Disk space
  - [ ] CPU utilization
  - [ ] Network connectivity
- [ ] Configured log analytics workspace
- [ ] Set up dashboard in Azure Portal

### 5. Nasuni Configuration
- [ ] Accessed Nasuni console for each appliance
- [ ] Completed initial setup wizard
- [ ] Connected to Nasuni Management Console
- [ ] Configured cache settings
- [ ] Set up file shares
- [ ] Tested file operations
- [ ] Configured sync schedules
- [ ] Set up monitoring/alerts in Nasuni

### 6. Documentation
- [ ] Updated network diagrams
- [ ] Documented IP addresses
- [ ] Created runbook for common operations
- [ ] Updated disaster recovery plan
- [ ] Created operational procedures
- [ ] Documented known issues
- [ ] Created troubleshooting guide

### 7. Handoff
- [ ] Trained operations team
- [ ] Provided access credentials (via secure method)
- [ ] Shared documentation
- [ ] Demonstrated common operations
- [ ] Scheduled follow-up review

## Rollback Plan (If Needed)

### In Case of Critical Issues:

1. **Immediate Actions**
   - [ ] Stop deployment: `Ctrl+C` (if still applying)
   - [ ] Assess impact and severity
   - [ ] Notify stakeholders
   - [ ] Document the issue

2. **Rollback Steps**
   - [ ] Select affected workspace: `terraform workspace select <workspace>`
   - [ ] Destroy failed resources: `terraform destroy`
   - [ ] OR destroy specific resource: `terraform destroy -target='module.nasuni_appliances["VM-NAME"]'`
   - [ ] Verify destruction in Azure Portal
   - [ ] Check for any orphaned resources
   - [ ] Clean up manually if needed

3. **Root Cause Analysis**
   - [ ] Identify what went wrong
   - [ ] Document the issue
   - [ ] Update deployment procedures
   - [ ] Fix the root cause
   - [ ] Test fix in non-production
   - [ ] Re-plan deployment

## Common Issues & Solutions

### Issue: Marketplace Terms Not Accepted
**Solution:**
```bash
az account set --subscription "<subscription-id>"
az vm image terms accept \
  --publisher nasunicorporation \
  --offer nasuni-nea-90-prod \
  --plan nasuni-nea-9153-prod
```

### Issue: Resource Group Doesn't Exist
**Solution:**
```bash
./scripts/create-resource-groups.sh
# OR manually:
az group create --name "RG-NAME" --location "LOCATION"
```

### Issue: Insufficient Permissions
**Solution:**
- Contact Azure administrator
- Verify RBAC roles assigned
- Check subscription access

### Issue: State Lock Error
**Solution:**
```bash
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Issue: Network Conflict
**Solution:**
- Verify VNet/Subnet exists
- Check CIDR ranges don't overlap
- Confirm subnet has available IPs

### Issue: No Appliances in Workspace
**Solution:**
- Verify workspace mapping in `locals.tf`
- Check CSV has VMs with correct subscription_id
- Confirm you're in correct workspace: `terraform workspace show`

## Maintenance Checklist (Recurring)

### Weekly
- [ ] Review Azure Activity Logs
- [ ] Check VM health status
- [ ] Review security alerts
- [ ] Check disk space utilization

### Monthly
- [ ] Review and rotate credentials (if not automated)
- [ ] Review NSG rules for accuracy
- [ ] Update Nasuni appliances (per Nasuni schedule)
- [ ] Review monitoring dashboards
- [ ] Check for Terraform updates
- [ ] Review state file backups

### Quarterly
- [ ] Full security review
- [ ] Disaster recovery test
- [ ] Performance optimization review
- [ ] Cost optimization review
- [ ] Update documentation
- [ ] Review and update this checklist

## Sign-off

### Deployment Approval
- **Requested by:** _____________________ Date: ___________
- **Reviewed by:** _____________________ Date: ___________
- **Approved by:** _____________________ Date: ___________

### Deployment Completion
- **Deployed by:** _____________________ Date: ___________
- **Verified by:** _____________________ Date: ___________
- **Handed off to:** _____________________ Date: ___________

### Notes
```
[Add any additional notes, issues, or observations here]
```

---

## Quick Reference

### Essential Commands
```bash
# Verify access
./scripts/verify-subscriptions.sh

# Validate CSV
./scripts/validate-csv.sh

# Create resource groups
./scripts/create-resource-groups.sh

# Initialize Terraform
terraform init

# Select workspace
terraform workspace select <workspace>

# Plan deployment
terraform plan -out=<workspace>.tfplan

# Apply deployment
terraform apply <workspace>.tfplan

# View outputs
terraform output nasuni_appliances

# Destroy (if needed)
terraform destroy
```

### Emergency Contacts
- **Azure Support:** [Your support contact]
- **Nasuni Support:** support@nasuni.com
- **Internal Infrastructure Team:** [Your team contact]
- **Security Team:** [Your security contact]

### Important Links
- [Azure Portal](https://portal.azure.com)
- [Nasuni Management Console](https://your-nasuni-console-url)
- [Internal Documentation](https://your-docs-url)
- [Terraform Registry](https://registry.terraform.io/)

---

**Last Updated:** December 2024  
**Next Review:** March 2025  
**Version:** 2.0