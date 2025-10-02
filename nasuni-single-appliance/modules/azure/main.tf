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
}

# Create Network Security Group
resource "azurerm_network_security_group" "nasuni" {
  name                = "${var.name_prefix}-nsg"
  location            = data.azurerm_resource_group.nasuni.location
  resource_group_name = data.azurerm_resource_group.nasuni.name
  tags                = var.tags
}

# Create Security Rules
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

# Create Network Interface (without public IP due to security policy)
resource "azurerm_network_interface" "nasuni" {
  name                = "${var.name_prefix}-nic"
  location            = data.azurerm_resource_group.nasuni.location
  resource_group_name = data.azurerm_resource_group.nasuni.name
  tags                = var.tags

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

# Create Managed Disk for cache
resource "azurerm_managed_disk" "cache" {
  name                 = "${var.name_prefix}-cache-disk"
  location             = data.azurerm_resource_group.nasuni.location
  resource_group_name  = data.azurerm_resource_group.nasuni.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.cache_disk_size_gb
  tags                 = var.tags
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "nasuni" {
  name                = var.vm_name
  location            = data.azurerm_resource_group.nasuni.location
  resource_group_name = data.azurerm_resource_group.nasuni.name
  size                = var.vm_size
  admin_username      = var.admin_username
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
}

# Attach cache disk
resource "azurerm_virtual_machine_data_disk_attachment" "cache" {
  managed_disk_id    = azurerm_managed_disk.cache.id
  virtual_machine_id = azurerm_linux_virtual_machine.nasuni.id
  lun                = "0"
  caching            = "ReadWrite"
}