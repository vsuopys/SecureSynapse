terraform {
  required_version = ">= 0.13"
}

provider "azurerm" {
	features {}
}

variable resourceGroupName {
	type        = string
	default     = "rg-secsyn-tf2"
	description = "Name of the resource group to deploy into"
}

variable resourceGroupLocation {
	type        = string
	default     = "East US"
	description = "Region to deploy the vNet"
}

variable createVnet {
  type        = bool
  default     = false
  description = "Create a Vnet?"
}

resource "azurerm_resource_group" "deploymentRG" {
	name     = var.resourceGroupName
	location = var.resourceGroupLocation
}

module "deployVnet" {
  source = "./modules/01-Vnet"
  createVnet  = var.createVnet
  resourceGroupName = var.resourceGroupName
  resourceGroupLocation = var.resourceGroupLocation
}
