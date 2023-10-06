resource "azurerm_resource_group" "toolbox_rg" {
  name = "toolbox-rg"
  location = "eastus2"
}

resource "azurerm_virtual_network" "default_vnet" {
  name = "az_mugiwara_internal"
  location = "eastus2"
  resource_group_name = azurerm_resource_group.toolbox_rg.name
  address_space = ["10.2.0.0/16"]
}

resource "azurerm_network_interface" "default_nic" {
  count = var.vm_count
  name = "nic_${count.index}"
  resource_group_name = azurerm_resource_group.default_rg.name
  location = azurerm_resource_group.default_rg.location
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.default_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "alt_nic" {
  count = var.vm_count
  name = "altnic_${count.index}"
  resource_group_name = azurerm_resource_group.default_rg.name
  location = azurerm_resource_group.default_rg.location
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.default_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_subnet" "default_subnet" {
  name = "default"
  virtual_network_name = azurerm_virtual_network.default_vnet.name
  address_prefixes = ["10.2.0.0/24"]
  resource_group_name = azurerm_resource_group.toolbox_rg.name
}

resource "azurerm_network_security_group" "default_nsg" {
  name = "default"
  location = azurerm_resource_group.toolbox_rg.location
  resource_group_name = azurerm_resource_group.toolbox_rg.name
}

resource "azurerm_subnet_network_security_group_association" "default_nsg_assoc" {
  subnet_id = azurerm_subnet.default_subnet.id
  network_security_group_id = azurerm_network_security_group.default_nsg.id
}

resource "azurerm_resource_group" "default_rg" {
  name = "az_splunkpractice_rg"
  location = "eastus2"
}

resource "azurerm_virtual_machine" "default_vms" {
  count = var.vm_count
  name = "testvm${count.index}"
  location = azurerm_resource_group.default_rg.location
  resource_group_name = azurerm_resource_group.default_rg.name
  network_interface_ids = [azurerm_network_interface.default_nic[count.index].id]
  vm_size = "Standard_B2ats_V2"
  delete_os_disk_on_termination = true

  storage_os_disk {
    name = "osdisk${count.index}"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-focal"
    sku = "20_04-lts"
    version = "latest"
  }
  os_profile {
    admin_username = "rohan"
    computer_name = "testvm${count.index}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/authorized_keys")
      path = "/home/rohan/.ssh/authorized_keys"
    }
  }
}

resource "azurerm_virtual_machine" "alt_vms" {
  count = var.vm_count
  name = "altvm${count.index}"
  location = azurerm_resource_group.default_rg.location
  resource_group_name = azurerm_resource_group.default_rg.name
  network_interface_ids = [azurerm_network_interface.alt_nic[count.index].id]
  vm_size = "Standard_B2ats_V2"
  delete_os_disk_on_termination = true

  storage_os_disk {
    name = "altosdisk${count.index}"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7_9-gen2"
    version = "latest"
  }
  os_profile {
    admin_username = "rohan"
    computer_name = "altvm${count.index}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/authorized_keys")
      path = "/home/rohan/.ssh/authorized_keys"
    }
  }
}

# variables
# count of virtual machines
variable "vm_count" {
  default = 0
}