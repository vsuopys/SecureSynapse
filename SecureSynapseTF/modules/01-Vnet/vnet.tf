# terraform {
# 	required_version = ">= 0.13"
# }

# provider "azurerm" {
# 	features {}
# }

variable createVnet {
	type        = bool
	default     = false
	description = "Should I do anything?"
}

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

variable vnetCidr {
	type        = string
	default     = "172.21.0.0/16"
	description = "Name of the vNet to deploy"
}

variable defaultSubnetName {
	type        = string
	default     = "default"
	description = "Name of the default subnet to deploy"
}

variable gatewaySubnetName {
	type        = string
	default     = "GatewaySubnet"
	description = "Name of the gateway subnet to deploy"
}

variable privateEndpointSubnetName {
	type        = string
	default     = "PrivateEndpointSubnet"
	description = "Name of the private endpoint subnet to deploy"
}

variable dataSubnetName {
	type        = string
	default     = "DataSubnet"
	description = "Name of the Data subnet to deploy"
}

variable defaultSubnetCidr {
	type        = string
	default     = "172.21.0.0/26"
	description = "CIDR of the default subnet to deploy"
}

variable gatewaySubnetCidr {
	type        = string
	default     = "172.21.1.0/26"
	description = "CIDR of the App subnet to deploy"
}

variable privateEndpointSubnetCidr {
	type        = string
	default     = "172.21.2.0/26"
	description = "CIDR of the private endpoint subnet to deploy"
}

variable dataSubnetCidr {
	type        = string
	default     = "172.21.3.0/26"
	description = "CIDR of the data subnet to deploy"
}

locals  {
    vnetNsgRules = {
        ARM-ServiceTag = {
            name = "ARM-ServiceTag"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "443"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: "AzureResourceManager"
            access: "Allow"
            priority: 3000
            direction: "Outbound"
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
        }
        FrontDoor-ServiceTag = {
            name: "FrontDoor-ServiceTag"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "443"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: "AzureFrontDoor.Frontend"
            access: "Allow"
            priority: 3010
            direction: "Outbound"
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
        }
        AAD-ServiceTag = {
            name: "AAD-ServiceTag"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "443"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: "AzureActiveDirectory"
            access: "Allow"
            priority: 3020
            direction: "Outbound"
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
        }
        Monitor-ServiceTag = {
            name: "Monitor-ServiceTag"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "443"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: "AzureMonitor"
            access: "Allow"
            priority: 3030
            direction: "Outbound"
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
        }
    }
    dataNsgRules = {
        RDP = {
            name: "RDP"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "3389"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: var.privateEndpointSubnetCidr
            access: "Allow"
            priority: 300
            direction: "Inbound"
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
        }
        HTTPS_Port_443 = {
            name: "HTTPS_Port_443"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "443"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: var.dataSubnetCidr
            access: "Allow"
            priority: 310
            direction: "Outbound"
            sourcePortRanges: []
            destinationPortRanges: []
            sourceAddressPrefixes: []
            destinationAddressPrefixes: []
        }
    }
    privateEndpointNsgRules = {
        RDP = {
            name: "RDP"
            protocol: "Tcp"
            sourcePortRange: "*"
            destinationPortRange: "3389"
            sourceAddressPrefix: "*"
            destinationAddressPrefix: var.privateEndpointSubnetCidr
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


# resource "azurerm_resource_group" "deploymentRG" {
# 	name     = var.resourceGroup
# 	location = var.resourceGroupLocation
# }

resource "azurerm_virtual_network" "vnet" {
    count               = var.createVnet ? 1 : 0
	name                = var.vnetName 
	address_space       = [var.vnetCidr]
	location            = var.resourceGroupLocation
	resource_group_name = var.resourceGroupName
}

resource "azurerm_subnet" "defaultSubnet" {
	count                = var.createVnet ? 1 : 0
    name                 = var.defaultSubnetName
	resource_group_name  = var.resourceGroupName
	virtual_network_name = azurerm_virtual_network.vnet[count.index].name
	address_prefixes     = [var.defaultSubnetCidr]
}

resource "azurerm_subnet" "gatewaySubnet" {
    count                = var.createVnet ? 1 : 0
    name                 = var.gatewaySubnetName
	resource_group_name  = var.resourceGroupName
	virtual_network_name = azurerm_virtual_network.vnet[count.index].name
	address_prefixes     = [var.gatewaySubnetCidr]
}

resource "azurerm_subnet" "privateEndpointSubnet" {
    count                = var.createVnet ? 1 : 0
	name                 = var.privateEndpointSubnetName
	resource_group_name  = var.resourceGroupName
	virtual_network_name = azurerm_virtual_network.vnet[count.index].name
	address_prefixes     = [var.privateEndpointSubnetCidr]
}

resource "azurerm_subnet" "dataSubnet" {
    count                = var.createVnet ? 1 : 0
	name                 = var.dataSubnetName
	resource_group_name  = var.resourceGroupName
	virtual_network_name = azurerm_virtual_network.vnet[count.index].name
	address_prefixes     = [var.dataSubnetCidr]
}

resource "azurerm_network_security_group" "vnetNsg" {
    count               = var.createVnet ? 1 : 0
	name                = "nsg-${var.vnetName}"
	location            = var.resourceGroupLocation
	resource_group_name = var.resourceGroupName
}

resource "azurerm_network_security_rule" "vnetNsgRules" {
	for_each                    = var.createVnet ? local.vnetNsgRules : {}
        name                        = each.key
        direction                   = each.value.direction
        access                      = each.value.access
        priority                    = each.value.priority
        protocol                    = each.value.protocol
        source_port_range           = each.value.sourcePortRange
        destination_port_range      = each.value.destinationPortRange
        source_address_prefix       = each.value.sourceAddressPrefix
        destination_address_prefix  = each.value.destinationAddressPrefix
        resource_group_name         = var.resourceGroupName
        network_security_group_name = azurerm_network_security_group.vnetNsg[0].name
    depends_on = [
        azurerm_network_security_group.vnetNsg[0]
    ]
}

resource "azurerm_network_security_group" "dataNsg" {
    count               = var.createVnet ? 1 : 0
	name                = "nsg-${var.dataSubnetName}"
	location            = var.resourceGroupLocation
	resource_group_name = var.resourceGroupName
}

resource "azurerm_network_security_rule" "dataNsgRules" {
	for_each                    = var.createVnet ? local.dataNsgRules : {} 
        name                        = each.key
        direction                   = each.value.direction
        access                      = each.value.access
        priority                    = each.value.priority
        protocol                    = each.value.protocol
        source_port_range           = each.value.sourcePortRange
        destination_port_range      = each.value.destinationPortRange
        source_address_prefix       = each.value.sourceAddressPrefix
        destination_address_prefix  = each.value.destinationAddressPrefix
        resource_group_name         = var.resourceGroupName
        network_security_group_name = azurerm_network_security_group.dataNsg[0].name
    depends_on = [
        azurerm_network_security_group.dataNsg[0]
    ]
}

resource "azurerm_network_security_group" "privateEndpointNsg" {
    count               = var.createVnet ? 1 : 0
	name                = "nsg-${var.privateEndpointSubnetName}"
	location            = var.resourceGroupLocation
	resource_group_name = var.resourceGroupName
}

resource "azurerm_network_security_rule" "privateEndpointNsgRules" {
	for_each                    = var.createVnet ? local.privateEndpointNsgRules : {}
        name                        = each.key
        direction                   = each.value.direction
        access                      = each.value.access
        priority                    = each.value.priority
        protocol                    = each.value.protocol
        source_port_range           = each.value.sourcePortRange
        destination_port_range      = each.value.destinationPortRange
        source_address_prefix       = each.value.sourceAddressPrefix
        destination_address_prefix  = each.value.destinationAddressPrefix
        resource_group_name         = var.resourceGroupName
        network_security_group_name = azurerm_network_security_group.privateEndpointNsg[0].name
    depends_on = [
        azurerm_network_security_group.privateEndpointNsg[0]
    ]
}