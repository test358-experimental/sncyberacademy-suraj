terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "sncollection-rg"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "sn_vnet" {
  name                = "snvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "sn_subnet" {
  name                 = "sn-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sn_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP (Standard SKU)
resource "azurerm_public_ip" "sn_pip" {
  name                = "sn-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "sn_nic" {
  name                = "sn-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "sn-ipconfig"
    subnet_id                     = azurerm_subnet.sn_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sn_pip.id
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "sn_vm" {
  name                = "sn-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D4s_v3"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.sn_nic.id
  ]

  admin_password = "Password@123!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
