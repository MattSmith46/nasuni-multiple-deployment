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
}

variable "admin_password" {
  description = "Admin password for all VMs"
  type        = string
  sensitive   = true
}