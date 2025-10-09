# terraform.tfvars - Multi-Subscription Nasuni Deployment Configuration

# IMPORTANT: This file contains sensitive credentials and should NEVER be committed to git
# It is already in .gitignore - keep it that way!

# Default subscription (used for the 'default' workspace if no workspace is selected)
# This should match one of your subscription IDs
default_subscription_id = "c7a18a12-7088-4955-8504-5156e8f48fdd"

# Admin credentials (used for all VMs across all subscriptions)
# SECURITY WARNING: Using plain text passwords is not recommended for production
# 
# RECOMMENDED APPROACHES:
# 1. Use environment variables (most secure):
#    export TF_VAR_admin_username="qadmin"
#    export TF_VAR_admin_password="your-secure-password"
#    Then remove these lines from this file
#
# 2. Use Azure Key Vault to store passwords
# 3. Use a secrets management tool like HashiCorp Vault
admin_username = "qadmin"
admin_password = "!!!HPVmw@r3!!!"  # CHANGE THIS! Use a strong password (12+ chars, mix of upper/lower/numbers/symbols)

# Path to your appliances CSV file
appliances_csv_path = "./appliances.csv"