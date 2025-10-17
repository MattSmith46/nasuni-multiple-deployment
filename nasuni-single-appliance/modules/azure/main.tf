# Use existing Resource Group
data "azurerm_resource_group" "nasuni" {
  name = var.resource_group_name
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Data source for existing VNet (if specified)
data "azurerm_virtual_network" "existing" {
  count               = var.existing_vnet_name != "" ? 1 : 0
  name                = var.existing_vnet_name
  resource_group_name = var.existing_vnet_resource_group
}

data "azurerm_subnet" "existing" {
  count                = var.existing_subnet_name != "" ? 1 : 0
  name                 = var.existing_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = var.existing_vnet_resource_group
}

# Create Virtual Network (only if not using existing)
resource "azurerm_virtual_network" "nasuni" {
  count               = var.existing_vnet_name == "" ? 1 : 0
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.network_cidr]
  location            = data.azurerm_resource_group.nasuni.location
  resource_group_name = data.azurerm_resource_group.nasuni.name
  
  # DNS servers for reverse lookup (if enabled)
  dns_servers         = var.enable_dns_reverse_lookup && length(var.dns_servers) > 0 ? var.dns_servers : null
  
  tags                = var.tags
}

# Create Subnet (only if not using existing)
resource "azurerm_subnet" "nasuni" {
  count                = var.existing_subnet_name == "" ? 1 : 0
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.nasuni.name
  virtual_network_name = azurerm_virtual_network.nasuni[0].name
  address_prefixes     = [var.subnet_cidr]
}

# Get the subnet reference (existing or new)
locals {
  subnet_id = var.existing_subnet_name != "" ? data.azurerm_subnet.existing[0].id : azurerm_subnet.nasuni[0].id
  
  # Extract reverse DNS zone name from subnet CIDR
  # For 10.239.4.0/24, this creates "4.239.10.in-addr.arpa"
  subnet_cidr_parts = var.enable_dns_reverse_lookup ? split(".", split("/", var.subnet_cidr)[0]) : []
  reverse_zone_name = var.enable_dns_reverse_lookup ? "${element(local.subnet_cidr_parts, 2)}.${element(local.subnet_cidr_parts, 1)}.${element(local.subnet_cidr_parts, 0)}.in-addr.arpa" : ""
}

# Create Network Security Group with improved naming
resource "azurerm_network_security_group" "nasuni" {
  name                = "${var.name_prefix}-nsg"
  location            = data.azurerm_resource_group.nasuni.location
  resource_group_name = data.azurerm_resource_group.nasuni.name
  tags                = var.tags
}

# Create Security Rules from variables
resource "azurerm_network_security_rule" "nasuni" {
  count = length(var.security_rules)

  name                        = var.security_rules[count.index].name
  priority                    = var.security_rules[count.index].priority
  direction                   = var.security_rules[count.index].direction
  access                      = var.security_rules[count.index].access
  protocol                    = var.security_rules[count.index].protocol
  source_port_range           = var.security_rules[count.index].source_port_range
  destination_port_range      = var.security_rules[count.index].destination_port_range
  source_address_prefix       = var.security_rules[count.index].source_address_prefix
  destination_address_prefix  = var.security_rules[count.index].destination_address_prefix
  resource_group_name         = data.azurerm_resource_group.nasuni.name
  network_security_group_name = azurerm_network_security_group.nasuni.name
}

# Create additional custom NSG rules
resource "azurerm_network_security_rule" "custom" {
  count = length(var.custom_nsg_rules)

  name                        = var.custom_nsg_rules[count.index].name
  priority                    = var.custom_nsg_rules[count.index].priority
  direction                   = var.custom_nsg_rules[count.index].direction
  access                      = var.custom_nsg_rules[count.index].access
  protocol                    = var.custom_nsg_rules[count.index].protocol
  source_port_range           = var.custom_nsg_rules[count.index].source_port_range
  destination_port_range      = var.custom_nsg_rules[count.index].destination_port_range
  source_address_prefix       = var.custom_nsg_rules[count.index].source_address_prefix
  destination_address_prefix  = var.custom_nsg_rules[count.index].destination_address_prefix
  resource_group_name         = data.azurerm_resource_group.nasuni.name
  network_security_group_name = azurerm_network_security_group.nasuni.name
}

# Create Network Interface with Accelerated Networking
resource "azurerm_network_interface" "nasuni" {
  name                          = "${var.name_prefix}-nic"
  location                      = data.azurerm_resource_group.nasuni.location
  resource_group_name           = data.azurerm_resource_group.nasuni.name
  accelerated_networking_enabled = var.enable_accelerated_networking
  tags                          = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "nasuni" {
  network_interface_id      = azurerm_network_interface.nasuni.id
  network_security_group_id = azurerm_network_security_group.nasuni.id
}

# Create Storage Account (if not provided)
resource "azurerm_storage_account" "nasuni" {
  count                    = var.storage_account_name == "" ? 1 : 0
  name                     = "nasuni${random_string.suffix.result}sa"
  resource_group_name      = data.azurerm_resource_group.nasuni.name
  location                 = data.azurerm_resource_group.nasuni.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  
  tags = var.tags
}

# Create Availability Set (optional - only if not provided)
resource "azurerm_availability_set" "nasuni" {
  count                        = var.availability_set_id == null ? 1 : 0
  name                         = "${var.name_prefix}-avset"
  location                     = data.azurerm_resource_group.nasuni.location
  resource_group_name          = data.azurerm_resource_group.nasuni.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = var.tags
}

# Determine which availability set to use
locals {
  availability_set_id = var.availability_set_id != null ? var.availability_set_id : (length(azurerm_availability_set.nasuni) > 0 ? azurerm_availability_set.nasuni[0].id : null)
}

# Create Managed Disk for cache - Premium SSD v2 support
resource "azurerm_managed_disk" "cache" {
  name                 = "${var.name_prefix}-cache-disk"
  location             = data.azurerm_resource_group.nasuni.location
  resource_group_name  = data.azurerm_resource_group.nasuni.name
  storage_account_type = var.disk_storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.cache_disk_size_gb
  
  # Premium SSD v2 specific settings
  disk_iops_read_write = var.disk_storage_account_type == "PremiumV2_LRS" ? var.disk_iops_read_write : null
  disk_mbps_read_write = var.disk_storage_account_type == "PremiumV2_LRS" ? var.disk_mbps_read_write : null
  
  tags = var.tags
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "nasuni" {
  name                = var.vm_name
  location            = data.azurerm_resource_group.nasuni.location
  resource_group_name = data.azurerm_resource_group.nasuni.name
  size                = var.vm_size
  admin_username      = var.admin_username
  
  # Availability Set (use provided or newly created)
  #availability_set_id = local.availability_set_id
  
  tags                = var.tags

  disable_password_authentication = false
  admin_password                 = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nasuni.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Nasuni NEA from Azure Marketplace
  source_image_reference {
    publisher = "nasunicorporation"
    offer     = "nasuni-nea-90-prod"
    sku       = "nasuni-nea-9153-prod"
    version   = "latest"
  }

  plan {
    name      = "nasuni-nea-9153-prod"
    product   = "nasuni-nea-90-prod"
    publisher = "nasunicorporation"
  }
  
  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = var.storage_account_name != "" ? null : (length(azurerm_storage_account.nasuni) > 0 ? azurerm_storage_account.nasuni[0].primary_blob_endpoint : null)
  }
}

# Attach cache disk
resource "azurerm_virtual_machine_data_disk_attachment" "cache" {
  managed_disk_id    = azurerm_managed_disk.cache.id
  virtual_machine_id = azurerm_linux_virtual_machine.nasuni.id
  lun                = "0"
  caching            = "ReadWrite"
}

# DNS Reverse Lookup Zone (if enabled)
resource "azurerm_private_dns_zone" "reverse_lookup" {
  count               = var.enable_dns_reverse_lookup ? 1 : 0
  name                = local.reverse_zone_name
  resource_group_name = data.azurerm_resource_group.nasuni.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "reverse_lookup" {
  count                 = var.enable_dns_reverse_lookup ? 1 : 0
  name                  = "${var.name_prefix}-dns-link"
  resource_group_name   = data.azurerm_resource_group.nasuni.name
  private_dns_zone_name = azurerm_private_dns_zone.reverse_lookup[0].name
  virtual_network_id    = var.existing_vnet_name != "" ? data.azurerm_virtual_network.existing[0].id : azurerm_virtual_network.nasuni[0].id
  tags                  = var.tags
}

resource "azurerm_private_dns_ptr_record" "nasuni" {
  count               = var.enable_dns_reverse_lookup ? 1 : 0
  name                = element(split(".", azurerm_network_interface.nasuni.private_ip_address), 3)
  zone_name           = azurerm_private_dns_zone.reverse_lookup[0].name
  resource_group_name = data.azurerm_resource_group.nasuni.name
  ttl                 = 300
  records             = ["${var.vm_name}.${var.existing_vnet_resource_group != "" ? var.existing_vnet_resource_group : data.azurerm_resource_group.nasuni.name}.local"]
  tags                = var.tags
}