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

variable createSynapseWs {
  type        = bool
  default     = true
  description = "Create a Synapse workspace?"
}

variable synapseName {
  type        = string
  default     = "secsyntf-ws"
  description = "Synapse workspace name"
}

variable synapseAdminName {
  type        = string
  default     = "adminuser"
  description = "Synapse administrator user name"
}

variable synapseAdminPassword {
  type        = string
  sensitive = true
  default     = ""
  description = "Synapse administrator password"
}

variable allowAllConnections {
  type        = bool
  default     = false
  description = "Allow all network connections"
}

variable workspaceIdentityRbacOnStorageAccount {
  type        = bool
  default     = true
  description = "Add Synapse MSI as storage blob contributor role to storage account"
}

variable storageAccountName {
  type        = string
  default     = "secsyntfadlac"
  description = "Storage account name"
}

variable storageFilesystemName {
  type        = string
  default     = "synapsefilesystem"
  description = "Container name for Synapse meta data"
}

variable grantWorkspaceIdentityControlForSql {
  type        = bool
  default     = true
  description = "Are pipelines (running as workspace's system assigned identity) allowed to access SQL pools?"
}

variable managedVirtualNetwork {
  type        = string
  default     = "default"
  description = "Name for SYnapse managed virtual network"
}

variable storageSubscriptionId {
  type        = string
  default     = ""
  description = "description"
}

variable storageLocation {
  type        = string
  default     = ""
  description = "Storage region"
}

variable isNewStorageAccount {
  type        = bool
  default     = true
  description = "Create a new storage account for Synapse metadata?"
}

variable isNewFileSystemOnly {
  type        = bool
  default     = false
  description = "description"
}

variable managedResourceGroupName {
  type        = string
  default     = ""
  description = "Auto assigned if blank"
}

variable storageAccessTier {
  type        = string
  default     = "Standard"
  description = "description"
}

variable storageAccountType {
  type        = string
  default     = "RAGRS"
  description = "description"
}

variable storageSupportsHttpsTrafficOnly {
  type        = bool
  default     = true
  description = "description"
}

variable storageKind {
  type        = string
  default     = "StorageV2"
  description = "description"
}

variable storageIsHnsEnabled {
  type        = bool
  default     = true
  description = "description"
}

variable userObjectId {
  type        = string
  default     = ""
  description = "Used to give a specific user RBAC on data lake"
}

variable setSbdcRbacOnStorageAccount {
  type        = bool
  default     = false
  description = "Used with userObjectId"
}

variable setWorkspaceMsiByPassOnStorageAccount {
  type        = bool
  default     = false
  description = "description"
}




resource "azurerm_resource_group" "deploymentRG" {
	count    = var.createRg ? 1 : 0
  name     = var.resourceGroupName
	location = var.resourceGroupLocation
}

module "deployVnet" {
  count                 = var.createVnet ? 1 : 0
  source 				        = "./modules/01-Vnet"
  resourceGroupName 	  = var.resourceGroupName
  resourceGroupLocation = var.resourceGroupLocation
  depends_on = [
    azurerm_resource_group.deploymentRG[0]
  ]
}

module "deployVm" {
  count                 = var.createVm ? 1 : 0
  source 				        = "./modules/02-Vm"
  resourceGroupName 	  = var.resourceGroupName
  resourceGroupLocation = var.resourceGroupLocation
  vnetName 				      = var.vnetName
  subnetId 				      = module.deployVnet[0].privateEndpointSubnetId
  nsgId 				        = module.deployVnet[0].privateEndpointNsgId
  vmAdminName 			    = var.vmAdminName
  vmAdminPassword 		  = var.vmAdminPassword
  depends_on = [
	  module.deployVnet[0]
  ]
}

module "deploySynapse" {
  count                 				        = var.createSynapseWs ? 1 : 0
  source 								                = "./modules/03-SynapseWs"
  resourceGroupName 					          = var.resourceGroupName
  resourceGroupLocation 				        = var.resourceGroupLocation
  synapseName							              = var.synapseName
  synapseAdminName 						          = var.synapseAdminName
  synapseAdminPassword 					        = var.synapseAdminPassword
  storageAccountName					          = var.storageAccountName
  storageFilesystemName					        = var.storageFilesystemName
  workspaceIdentityRbacOnStorageAccount = var.workspaceIdentityRbacOnStorageAccount
  grantWorkspaceIdentityControlForSql	  = var.grantWorkspaceIdentityControlForSql
  managedVirtualNetwork					        = var.managedVirtualNetwork
  storageSubscriptionId					        = var.storageSubscriptionId
  storageLocation						            = var.resourceGroupLocation
  isNewStorageAccount					          = var.isNewStorageAccount
  isNewFileSystemOnly					          = var.isNewFileSystemOnly
  managedResourceGroupName				      = var.managedResourceGroupName
  storageAccessTier						          = var.storageAccessTier
  storageAccountType					          = var.storageAccountType
  storageSupportsHttpsTrafficOnly		    = var.storageSupportsHttpsTrafficOnly
  storageKind							              = var.storageKind
  storageIsHnsEnabled					          = var.storageIsHnsEnabled
  storageNetworkRuleSubnetIds           = [module.deployVnet[0].privateEndpointSubnetId]
  userObjectId							            = var.userObjectId
  setSbdcRbacOnStorageAccount			      = var.setSbdcRbacOnStorageAccount
  setWorkspaceMsiByPassOnStorageAccount = var.setWorkspaceMsiByPassOnStorageAccount

  depends_on = [
    module.deployVnet[0]
  ]
}

# module "deploySynapseHub" {
#   count                 = var.createSynapseWs ? 1 : 0
#   source 				        = "./modules/04-SynapseHub"
#   resourceGroupLocation = var.resourceGroupLocation
#   hubName               = var.hubName
#   tagValues             = var.tagValues
#   depends_on = [
# 	  module.deploySynapse[0]
#   ]
# }
