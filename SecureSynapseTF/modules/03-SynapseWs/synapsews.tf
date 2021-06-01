variable resourceGroupName {
  type        = string
  default     = "rg-secsyn-tf"
  description = "Synapse resource group name"
}

variable resourceGroupLocation {
  type        = string
  default     = "East US"
  description = "Synapse deployment location"
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
  description = "Create container in existing storage account?"
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

variable storageNetworkRuleSubnetIds {
  type        = list(string)
  default     = []
  description = "Subnets that should have access to the Synapse storage account"
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



resource "azurerm_storage_account" "synapseStorageAccount" {
  name                      = var.storageAccountName
  resource_group_name       = var.resourceGroupName
  location                  = var.resourceGroupLocation
  account_kind              = var.storageKind
  account_tier              = var.storageAccessTier
  account_replication_type  = var.storageAccountType
  enable_https_traffic_only = var.storageSupportsHttpsTrafficOnly
  is_hns_enabled            = var.storageIsHnsEnabled
  
  network_rules {
    default_action             = "Deny"
    # virtual_network_subnet_ids = var.storageNetworkRuleSubnetIds
  }

  tags = {}
}

resource "azurerm_storage_container" "synapseFilesystem" {
  name                  = var.storageFilesystemName
  storage_account_name  = azurerm_storage_account.synapseStorageAccount.name
  container_access_type = "private"
}
# resource "azurerm_storage_data_lake_gen2_filesystem" "synapseFilesystem" {
#   name                  = var.storageFilesystemName
#   storage_account_id    = azurerm_storage_account.synapseStorageAccount.id
#   depends_on = [
#       azurerm_storage_account.synapseStorageAccount
#   ]
# }

resource "azurerm_synapse_workspace" "synapseWorkspace" {
  name                                  = var.synapseName
  resource_group_name                   = var.resourceGroupName
  location                              = var.resourceGroupLocation
  storage_data_lake_gen2_filesystem_id  = "https://${var.storageAccountName}.dfs.core.windows.net/default/${var.storageFilesystemName}"    #azurerm_storage_data_lake_gen2_filesystem.synapseFilesystem.id
  sql_administrator_login               = var.synapseAdminName
  sql_administrator_login_password      = var.synapseAdminPassword
  managed_virtual_network_enabled       = true
  sql_identity_control_enabled          = var.grantWorkspaceIdentityControlForSql
#   managed_resource_group_name           = var.managedResourceGroupName

  tags = {}
  depends_on = [
    azurerm_storage_container.synapseFilesystem
    #  azurerm_storage_data_lake_gen2_filesystem.synapseFilesystem
  ]
}

resource "azurerm_synapse_firewall_rule" "synapseFirewall" {
  count                 = var.allowAllConnections ? 1 : 0
  name                  = "AllowAll"
  synapse_workspace_id  = azurerm_synapse_workspace.synapseWorkspace.id
  start_ip_address      = "0.0.0.0"
  end_ip_address        = "255.255.255.255"

  depends_on = [
      azurerm_synapse_workspace.synapseWorkspace
  ]
}

resource "azurerm_role_assignment" "synapseStorageRBAC" {
  count              = var.workspaceIdentityRbacOnStorageAccount ? 1 : 0
  scope              = azurerm_storage_account.synapseStorageAccount.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azurerm_synapse_workspace.synapseWorkspace.identity.0.principal_id
  depends_on = [
      azurerm_storage_account.synapseStorageAccount,
      azurerm_synapse_workspace.synapseWorkspace
  ]
}

resource "azurerm_role_assignment" "userStorageRBAC" {
  count                = var.setSbdcRbacOnStorageAccount ? 1 : 0
  scope                = azurerm_storage_account.synapseStorageAccount.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.userObjectId
  depends_on = [
      azurerm_storage_account.synapseStorageAccount
  ]
}

