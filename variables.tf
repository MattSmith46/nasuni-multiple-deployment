variable "default_subscription_id" {
  description = "Default Azure subscription ID (used for 'default' workspace)"
  type        = string
  default     = "c7a18a12-7088-4955-8504-5156e8f48fdd"
}

variable "appliances_csv_path" {
  description = "Path to the CSV file containing appliance configurations"
  type        = string
  default     = "./appliances.csv"
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "azureuser"
  
  validation {
    condition     = length(var.admin_username) >= 3 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 3 and 20 characters."
  }
}

variable "admin_password" {
  description = "Admin password for all VMs. For production, use environment variable: export TF_VAR_admin_password='your-password'"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Admin password must be at least 12 characters long."
  }
}