terraform {
    required_version = " >= 0.13 "
    
    required_providers {
            azurerm = {
                source = "hashicorp/azurerm"
                version = " >= 2.26"
            }
    }
}

provider "azurerm" {
    features{

    }
}

resource "azurerm_resource_group" "rg-aulainfra-tgocs"{
    name = "aulainfracloudterratgocs"
    location = "centralus"
}

resource "azurerm_virtual_network" "vnet-aulainfra-tgocs" {
  name                = "vnet-aulainfra-tgocs"
  location            = azurerm_resource_group.rg-aulainfra-tgocs.location
  resource_group_name = azurerm_resource_group.rg-aulainfra-tgocs.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Testes"
    aluno = "Tiago de Campos Sabor"
  }
}

resource "azurerm_subnet" "subnet-aulainfra-tgocs" {
  name                 = "subnet-aulainfra-tgocs"
  resource_group_name  = azurerm_resource_group.rg-aulainfra-tgocs.name
  virtual_network_name = azurerm_virtual_network.vnet-aulainfra-tgocs.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_public_ip" "ip-aulainfra-tgocs" {
  name                    = "pip-aulainfra-tgocs"
  location                = azurerm_resource_group.rg-aulainfra-tgocs.location
  resource_group_name     = azurerm_resource_group.rg-aulainfra-tgocs.name
  allocation_method       = "Static"

  tags = {
    environment = "Testes"
  }
}

resource "azurerm_network_security_group" "nsg-aulainfra-tgocs" {
  name                = "nsg-aulainfra-tgocs"
  location            = azurerm_resource_group.rg-aulainfra-tgocs.location
  resource_group_name = azurerm_resource_group.rg-aulainfra-tgocs.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Web"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Testes"
  }
}

resource "azurerm_network_interface" "nic-aulainfra-tgocs" {
  name                = "nic-aulainfra-tgocs"
  location            = azurerm_resource_group.rg-aulainfra-tgocs.location
  resource_group_name = azurerm_resource_group.rg-aulainfra-tgocs.name

  ip_configuration {
    name                          = "nic-ip"
    subnet_id                     = azurerm_subnet.subnet-aulainfra-tgocs.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip-aulainfra-tgocs.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-aulainfra-tgocs" {
  network_interface_id = azurerm_network_interface.nic-aulainfra-tgocs.id
  network_security_group_id = azurerm_network_security_group.nsg-aulainfra-tgocs.id
}

resource "azurerm_storage_account" "saaulainfratgocs" {
  name                     = "storageaccounttgocs"
  resource_group_name      = azurerm_resource_group.rg-aulainfra-tgocs.name
  location                 = azurerm_resource_group.rg-aulainfra-tgocs.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Testes"
  }
}

resource "azurerm_linux_virtual_machine" "vm-aulainfra-tgocs" {
  name                = "vm-aulainfra-tgocs"
  resource_group_name = azurerm_resource_group.rg-aulainfra-tgocs.name
  location            = azurerm_resource_group.rg-aulainfra-tgocs.location
  size                = "Standard_D2ads_v5"
  
  network_interface_ids = [
    azurerm_network_interface.nic-aulainfra-tgocs.id
  ]
  
  admin_username      = "adminuser"
  admin_password = "Senh@1234"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "disco-tgocs"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.saaulainfratgocs.primary_blob_endpoint
  }

}

data "azurerm_public_ip" "ip-aulainfra-data" {
    name = azurerm_public_ip.ip-aulainfra-tgocs.name
    resource_group_name = azurerm_resource_group.rg-aulainfra-tgocs.name
}

resource "null_resource" "install-webserver" {

  connection {
    type = "ssh"
    host = data.azurerm_public_ip.ip-aulainfra-data.ip_address
    user = var.user
    password = var.password
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2"
    ]
  }

    depends_on = [
      azurerm_linux_virtual_machine.vm-aulainfra-tgocs
    ]

}

variable "user" {
    description = "VM User"
    type = string
  
}

variable "password" {

}