variable resourceGroupName {
	type        = string
	default     = "rg-secsyn-tf"
	description = "Name of the resource group to deploy into"
}

variable resourceGroupLocation {
	type        = string
	default     = "East US"
	description = "Region to deploy the vNet"
}

variable vnetName {
	type        = string
	default     = "vnet-customer-tf"
	description = "Name of the vNet to deploy"
}

variable nsgId {
  type        = string
  default     = ""
  description = "ID of NSG to apply to VM NIC"
}

variable subnetId {
	type        = string
	default     = "PrivateEndpointSubnet"
	description = "ID of the private endpoint subnet to deploy"
}

variable vmName {
	type        = string
	default     = "VM"
	description = "VM administrator account name"
}

variable vmAdminName {
	type        = string
	default     = "cloudsa"
	description = "VM administrator account name"
}

variable vmAdminPassword {
	type        = string
	default     = ""
	description = "VM administrator password"
}

variable publicIpAddressType {
  type        = string
  default     = "Static"
  description = "IP type"
}

variable publicIpAddressSku {
  type        = string
  default     = "Basic"
  description = "IP SKU"
}

variable osDiskType {
  type        = string
  default     = "StandardSSD_LRS"
  description = "VM disk type"
}

variable virtualMachineSize {
  type        = string
  default     = "Standard_DS11_v2"
  description = "VM machine size"
}

resource "random_id" "uniquesuffix" {
  keepers = {
      depkey = "${var.resourceGroupName}${var.resourceGroupLocation}"
  }
  byte_length = 8
}

locals {
  vmNsgRules = {
    RDP = {
        name: "RDP"
        protocol: "Tcp"
        sourcePortRange: "*"
        destinationPortRange: "3389"
        sourceAddressPrefix: "*"
        access: "Allow"
        priority: 300
        direction: "Inbound"
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
    }
  }
}

resource "azurerm_public_ip" "publicIpResource" {
  name                = "ip-${lower(var.vmName)}${lower(replace(random_id.uniquesuffix.id, "/[^a-zA-Z0-9]/", "-"))}"
  resource_group_name = var.resourceGroupName
  location            = var.resourceGroupLocation
  sku                 = "Basic"
  allocation_method   = var.publicIpAddressType  
}

resource "azurerm_network_interface" "nicResource" {
  name                = "nic-${lower(var.vmName)}${lower(replace(random_id.uniquesuffix.id, "/[^a-zA-Z0-9]/", "-"))}"
  location            = var.resourceGroupLocation
  resource_group_name = var.resourceGroupName

  ip_configuration {
    name                          = "nicconfig1"
    subnet_id                     = var.subnetId
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicIpResource.id
  }
}

resource "azurerm_network_security_group" "vmNsg" {
	name                = "nsg-${lower(var.vmName)}-${lower(replace(random_id.uniquesuffix.id, "/[^a-zA-Z0-9]/", "-"))}"
	location            = var.resourceGroupLocation
	resource_group_name = var.resourceGroupName
}

resource "azurerm_network_security_rule" "vmNsgRules" {
	for_each                    = local.vmNsgRules
        name                        = each.key
        direction                   = each.value.direction
        access                      = each.value.access
        priority                    = each.value.priority
        protocol                    = each.value.protocol
        source_port_range           = each.value.sourcePortRange
        destination_port_range      = each.value.destinationPortRange
        source_address_prefix       = each.value.sourceAddressPrefix
        destination_address_prefix  = azurerm_public_ip.publicIpResource.ip_address
        resource_group_name         = var.resourceGroupName
        network_security_group_name = azurerm_network_security_group.vmNsg.name
    depends_on = [
        azurerm_network_security_group.vmNsg,
        azurerm_public_ip.publicIpResource
    ]
}

resource "azurerm_network_interface_security_group_association" "nsg-nicDeployment" {
  network_interface_id      = azurerm_network_interface.nicResource.id
  network_security_group_id = azurerm_network_security_group.vmNsg.id
  depends_on = [
    azurerm_network_interface.nicResource
  ]
}

resource "azurerm_windows_virtual_machine" "vmResource" {
  name                = "${lower(var.vmName)}-${lower(replace(random_id.uniquesuffix.id, "/[^a-zA-Z0-9]/", "-"))}"
  computer_name       = "${lower(var.vmName)}-${lower(replace(random_id.uniquesuffix.id, "/[^a-zA-Z0-9]/", "-"))}"
  resource_group_name = var.resourceGroupName
  location            = var.resourceGroupLocation
  size                = var.virtualMachineSize
  admin_username      = var.vmAdminName
  admin_password      = var.vmAdminPassword
  license_type        = "Windows_Client"
  enable_automatic_updates = true
  provision_vm_agent  = true

  network_interface_ids = [
    azurerm_network_interface.nicResource.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.osDiskType
  }
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pro"
    version   = "latest"
  }
  identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "aad" {
  name                       = "aad-${lower(var.vmName)}${lower(replace(random_id.uniquesuffix.id, "/[^a-zA-Z0-9]/", "-"))}"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.vmResource.id
  depends_on = [
    azurerm_windows_virtual_machine.vmResource
  ]
}