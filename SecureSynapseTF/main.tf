terraform {
  required_version = ">= 0.13"
}

provider "azurerm" {
	features {}
}

variable createRg {
  type        = bool
  default     = false
  description = "Create a new resource group?"
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

variable createVnet {
  type        = bool
  default     = true
  description = "Create a Vnet?"
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

variable createVm {
  type        = bool
  default     = false
  description = "Create a VM jumpbox?"
}

variable vmAdminName {
  type        = string
  default     = "cloudsa"
  description = "Administrator user name"
}

variable vmAdminPassword {
  type        = string
  sensitive = true
  default     = ""
  description = "Administrator password"
}

resource "azurerm_resource_group" "deploymentRG" {
	count    = var.createRg ? 1 : 0
  	name     = var.resourceGroupName
	location = var.resourceGroupLocation
}

module "deployVnet" {
  count                 = var.createVnet ? 1 : 0
  source 				= "./modules/01-Vnet"
  resourceGroupName 	= var.resourceGroupName
  resourceGroupLocation = var.resourceGroupLocation
  depends_on = [
	azurerm_resource_group.deploymentRG[0]
  ]
}

module "deployVm" {
  count                 = var.createVm ? 1 : 0
  source 				= "./modules/02-Vm"
  resourceGroupName 	= var.resourceGroupName
  resourceGroupLocation = var.resourceGroupLocation
  vnetName 				= var.vnetName
  subnetId 				= module.deployVnet[0].privateEndpointSubnetId
  nsgId 				= module.deployVnet[0].privateEndpointNsgId
  vmAdminName 			= var.vmAdminName
  vmAdminPassword 		= var.vmAdminPassword
  depends_on = [
	  module.deployVnet[0]
  ]
}