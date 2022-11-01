terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.90.0"
    }
  }
}

provider "azurerm" {
    features {}
}


resource "azurerm_resource_group" "azresource" {
  name     = "New-TF-RG"
  location = "East US"
}

resource "azurerm_virtual_network" "azvnet" {
  name                = "New-TF-VN"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azresource.location
  resource_group_name = azurerm_resource_group.azresource.name
}

resource "azurerm_subnet" "azsubnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.azresource.name
  virtual_network_name = azurerm_virtual_network.azvnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "aznic" {
  name                = "New-TF-nic"
  location            = azurerm_resource_group.azresource.location
  resource_group_name = azurerm_resource_group.azresource.name
  
    ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azpip.id
  }
    
  }

  resource "azurerm_public_ip" "azpip" {
  name                = "TFPublicIp1"
  resource_group_name = azurerm_resource_group.azresource.name
  location            = azurerm_resource_group.azresource.location
  allocation_method   = "Static"
}


resource "azurerm_windows_virtual_machine" "azvm" {
  name                = "New-TF-EUS-01"
  resource_group_name = azurerm_resource_group.azresource.name
  location            = azurerm_resource_group.azresource.location
  size                = "standard_B1s"
  admin_username      = "ap-admin"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.aznic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 256
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "azmgmtdisk" {
  name                 = "Datadisk1"
  location             = azurerm_resource_group.azresource.location
  resource_group_name  = azurerm_resource_group.azresource.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}

resource "azurerm_virtual_machine_data_disk_attachment" "azdiskattach" {
  managed_disk_id    = azurerm_managed_disk.azmgmtdisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.azvm.id
  lun                = "10"
  caching            = "ReadWrite"
}


