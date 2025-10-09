locals {
  name_prefix = "${var.vm_name}-${var.environment}"
  
  # Security rules without SSH (removed due to security policy)
  # SECURITY NOTE: These rules currently allow traffic from any source (*)
  # For production, replace "*" with specific IP ranges or VirtualNetwork
  # Example: source_address_prefix = "10.0.0.0/8" for internal traffic only
  #          source_address_prefix = "VirtualNetwork" for VNet traffic only
  security_rules = [
    {
      name                       = "HTTPS"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"  # Changed from "*" - only allow VNet traffic
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
      source_address_prefix      = "VirtualNetwork"  # Changed from "*" - only allow VNet traffic
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
      source_address_prefix      = "VirtualNetwork"  # Changed from "*" - only allow VNet traffic
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
      source_address_prefix      = "VirtualNetwork"  # Changed from "*" - only allow VNet traffic
      destination_address_prefix = "*"
    }
  ]
}