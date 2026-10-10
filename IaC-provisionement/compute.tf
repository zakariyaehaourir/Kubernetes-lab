resource "azurerm_network_interface" "nic-instances" {
  count               = 3
  name                = "nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.global.name

  ip_configuration {
    name                          = "internal-ip-config"
    subnet_id                     = azurerm_subnet.k8s-lab_Default_Subnet.id
    private_ip_address_allocation = "Static"

    private_ip_address = "10.0.1.${4 + count.index}" #begin from .5 
    public_ip_address_id = (
      count.index == 0 ? azurerm_public_ip.public_ip.id :null
    )
  }
}

resource "azurerm_linux_virtual_machine" "virtual_linux_instances" {
  for_each            = var.vm_instances
  name                = each.key
  resource_group_name = azurerm_resource_group.global.name
  location            = var.location
  size                = each.value.size
  #zone = 3

  network_interface_ids = [azurerm_network_interface.nic-instances[index(keys(var.vm_instances), each.key)].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = each.value.os_publisher
    offer     = each.value.os_offer
    sku       = each.value.os_sku
    version   = each.value.os_version
  }
  admin_username = var.vm_auth_config.username
  admin_ssh_key {
    username   = var.vm_auth_config.username
    public_key = file(var.vm_auth_config.ssh_file)
  }
}