resource "azurerm_virtual_network" "k8s_lab_vnet" {
  name                = "k8s-lab-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.global.name
  address_space       = var.k8s_network_cidr

  tags = {
    Environment = var.env
    Project     = var.project
  }
}

resource "azurerm_subnet" "k8s-lab_Default_Subnet" {
  name                 = "default-subnet"
  resource_group_name  = azurerm_resource_group.global.name
  virtual_network_name = azurerm_virtual_network.k8s_lab_vnet.name
  address_prefixes     = var.vms_subnet
  depends_on = [azurerm_virtual_network.k8s_lab_vnet]
}

resource "azurerm_subnet_network_security_group_association" "associate-subnet-global-nsg" {
  subnet_id                 = azurerm_subnet.k8s-lab_Default_Subnet.id
  network_security_group_id = azurerm_network_security_group.global.id
}

resource "azurerm_public_ip" "public_ip" {
  name = "pip-k8s-master"
  resource_group_name =azurerm_resource_group.global.name
  location = var.location
  allocation_method ="Static"
  sku = "Standard"
}