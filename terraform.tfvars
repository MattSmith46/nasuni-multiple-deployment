# terraform.tfvars - Multi-Subscription Nasuni Deployment Configuration

# Default subscription (used for Terraform state and provider)
# Use one of your subscription IDs as the default
default_subscription_id = "c7a18a12-7088-4955-8504-5156e8f48fdd"

# Map your subscription IDs to friendly aliases
# Add as many as needed - you have 3 unique subscriptions
subscription_aliases = {
  sub1 = "c7a18a12-7088-4955-8504-5156e8f48fdd"  # PGR Subscription
  sub2 = "6b025554-fc3d-49a6-a9a1-56d397909042"  # QIS Subscription
  sub3 = "8f054358-9640-4873-a3bf-f1e3547ed39f"  # QTI Subscription
  sub4 = ""  # Not used - leave empty or add another if needed
}

# Admin credentials (used for all VMs across all subscriptions)
# These will be the login credentials for all Nasuni appliances
admin_username = "qadmin"
admin_password = "!!!HPVmw@r3!!!"  # CHANGE THIS!

# Option 2: Git repository (if using version control)
# module_source = "git::https://github.com/your-org/nasuni-single-appliance.git"

# Option 3: Git with specific version/tag
# module_source = "git::https://github.com/your-org/nasuni-single-appliance.git?ref=v1.0.0"

# Path to your appliances CSV file
appliances_csv_path = "./appliances.csv"