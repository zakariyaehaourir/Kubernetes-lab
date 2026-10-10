resource "azurerm_network_security_group" "global" {
  name                = "nsg-shared"
  location            = var.location
  resource_group_name = azurerm_resource_group.global.name

  security_rule {
    name                       = "open-ssh-port"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "22"
    destination_address_prefix = "*"
    priority                   = 100
    source_port_range          = "*"
    source_address_prefix      = "*"
  }
}