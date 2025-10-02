locals {
  name_prefix = "${var.vm_name}-${var.environment}"
  
  # Security rules without SSH (removed due to security policy)
  security_rules = [
    {
      name                       = "HTTPS"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "NasuniConsole"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "SMB"
      priority                   = 1004
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "445"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "NFS"
      priority                   = 1005
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "2049"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}