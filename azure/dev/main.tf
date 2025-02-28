
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "dev"
  location = "East US"
}

# Create a Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "dev-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create Subnets
resource "azurerm_subnet" "private_subnet" {
  name                 = "dev-private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "dev-gateway-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create a Network Security Group (NSG) for Private Subnet
resource "azurerm_network_security_group" "private_nsg" {
  name                = "dev-private-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Private Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# Create a Public IP for Gateway Server
resource "azurerm_public_ip" "gateway_public_ip" {
  name                = "dev-gateway-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create Network Interface for Gateway Server
resource "azurerm_network_interface" "gateway_nic" {
  name                = "dev-gateway-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "dev-gateway-ip-config"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.10"
    public_ip_address_id          = azurerm_public_ip.gateway_public_ip.id
  }
}

# Create the Gateway Server VM
resource "azurerm_linux_virtual_machine" "gateway_vm" {
  name                = "dev-gateway-server"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [azurerm_network_interface.gateway_nic.id]

  admin_ssh_key {
    username   = "mveetil"
    public_key = file("~/.ssh/id_rsa.pub")
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

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE",
      "echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p"
    ]

    connection {
      type        = "ssh"
      user        = "mveetil"
      private_key = file("~/.ssh/id_rsa")
      host        = azurerm_public_ip.gateway_public_ip.ip_address
    }
  }
}

# Create Network Interface for Private VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "dev-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "dev-private-ip-config"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

# Create a Private VM Without Public IP
resource "azurerm_linux_virtual_machine" "private_vm" {
  name                = "dev-private-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  admin_ssh_key {
    username   = "mveetil"
    public_key = file("~/.ssh/id_rsa.pub")
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

  provisioner "remote-exec" {
    inline = [
      "sudo ip route add default via 10.0.2.10"
    ]

    connection {
      type        = "ssh"
      user        = "mveetil"
      private_key = file("~/.ssh/id_rsa")
      host        = azurerm_network_interface.vm_nic.private_ip_address
    }
  }
}

# Outputs
output "gateway_public_ip" {
  value = azurerm_public_ip.gateway_public_ip.ip_address
}

output "private_vm_ip" {
  value = azurerm_network_interface.vm_nic.private_ip_address
}