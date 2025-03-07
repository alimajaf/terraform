provider "azurerm" {
  features {}
}

# Define the resource group
#resource "azurerm_resource_group" "rg" {
#  name     = "mveetil"
#  location = "centralindia"
#}

# Create a virtual network
#resource "azurerm_virtual_network" "vnet" {
#  name                = "AdminServer-vnet"
#  location            = "eastus2"
#  resource_group_name = azurerm_resource_group.rg.name
#  address_space       = ["10.0.0.0/16"]
#}

# Create a subnet within the VNet
#resource "azurerm_subnet" "subnet" {
#  name                 = "default"
#  resource_group_name  = azurerm_resource_group.rg.name
#  virtual_network_name = azurerm_virtual_network.vnet.name
#  address_prefixes     = ["10.0.0.0/24"]
#}

# Create a private network interface (No Public IP)
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = "eastus2"
  resource_group_name = "mveetil"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/c32c2cc0-faf3-44b3-b41a-0e5ee014301a/resourceGroups/mveetil/providers/Microsoft.Network/virtualNetworks/AdminServer-vnet/subnets/default"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.5"
  }
}

# Define the Debian 12 virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "debian12vm"
  resource_group_name   = "mveetil"
  location              = "eastus2"
  size                  = "Standard_B1s" # Change as needed
  admin_username        = "mveetil"
  network_interface_ids = [azurerm_network_interface.nic.id]

  # SSH key-based authentication
  admin_ssh_key {
    username   = "mveetil"
    public_key = file("~/.ssh/id_rsa.pub") # Ensure this file exists
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }

    custom_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Setting up network configuration..."

    # Configure the default gateway
    ip route add default via 10.0.0.4

    # Set up DNS server
    echo "nameserver 8.8.8.8" > /etc/resolv.conf

    echo "Network configuration applied."
  EOF
  )
}

# Output the private IP address for SSH access
output "private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}
