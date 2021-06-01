param workspaceName string
param location string = resourceGroup().location
param defaultDataLakeStorageAccountName string = 'secbicadlac'
param defaultDataLakeStorageFilesystemName string = 'synapsefilesystem'
param sqlAdministratorLogin string = 'adminuser'

@secure()
param sqlAdministratorLoginPassword string = ''

param setWorkspaceIdentityRbacOnStorageAccount bool = true
param allowAllConnections bool = false

@allowed([
  'Enabled'
  'Disabled'
])
param grantWorkspaceIdentityControlForSql string = 'Enabled'

@allowed([
  'default'
  ''
])
param managedVirtualNetwork string = 'default'

param managedVirtualNetworkSettings object
param tagValues object = {}

// Storage parameters
param storageSubscriptionID string = subscription().subscriptionId
param storageLocation string = resourceGroup().location
param storageRoleUniqueId string = newGuid()
param isNewStorageAccount bool = true
param isNewFileSystemOnly bool = true
// param adlaResourceId string = ''
param managedResourceGroupName string = ''   // auto assigned if blank
param storageAccessTier string = 'Hot'
param storageAccountType string = 'Standard_RAGRS'
param storageSupportsHttpsTrafficOnly bool = true
param storageKind string = 'StorageV2'
param storageIsHnsEnabled bool = true
param userObjectId string = ''   // used to give a specific user RBAC on data lake
param setSbdcRbacOnStorageAccount bool = false   // used with userObjectId
param setWorkspaceMsiByPassOnStorageAccount bool = false
param workspaceStorageAccountProperties object = {}


var storageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var defaultDataLakeStorageAccountUrl = 'https://${defaultDataLakeStorageAccountName}.dfs.core.windows.net'

var workspaceStorageRBACName = '${guid(resourceGroup().name, 'Workspace Storage Blob Contributor')}'   // value needs to be consistent across deployment runs

var userStorageRBACName = '${guid(resourceGroup().name, 'User Storage Blob Contributor')}'   // value needs to be consistent across deployment runs

var webEndpoint = 'https://web.azuresynapse.net?workspace=%2fsubscriptions%2f${storageSubscriptionID}%2fresourceGroups%2f${location}%2fproviders%2fMicrosoft.Synapse%2fworkspaces%2f${workspaceName}'
var devEndpoint = 'https://${workspaceName}.dev.azuresynapse.net'
var onDemandEndpoint = '${workspaceName}-ondemand.sql.azuresynapse.net'
var sqlEndpoint = '${workspaceName}.sql.azuresynapse.net'

resource defaultDataLakeStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2021-02-01' = if (isNewStorageAccount) {
  name: defaultDataLakeStorageAccountName
  location: storageLocation
  properties: {
    accessTier: storageAccessTier
    supportsHttpsTrafficOnly: storageSupportsHttpsTrafficOnly
    isHnsEnabled: storageIsHnsEnabled
    networkAcls: {
       defaultAction: 'Deny'
    }
    allowBlobPublicAccess: false
  }
  sku: {
    name: storageAccountType
  }
  kind: storageKind
  tags: {}
}

resource defaultDataLakeStorageAccountName_default_defaultDataLakeStorageFilesystemName 'Microsoft.Storage/storageAccounts/blobServices/containers@2018-02-01' = if (isNewFileSystemOnly) {
  name: '${defaultDataLakeStorageAccountName}/default/${defaultDataLakeStorageFilesystemName}'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    defaultDataLakeStorageAccountName_resource
  ]
}

resource synapseWorkspace_resource 'Microsoft.Synapse/workspaces@2021-03-01' = {
  name: workspaceName
  tags: tagValues
  location: location
  properties: {
    defaultDataLakeStorage: {
      accountUrl: defaultDataLakeStorageAccountUrl
      filesystem: defaultDataLakeStorageFilesystemName
    }
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
//    adlaResourceId: adlaResourceId
    managedVirtualNetwork: managedVirtualNetwork
    managedResourceGroupName: managedResourceGroupName
    managedVirtualNetworkSettings: managedVirtualNetworkSettings
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    defaultDataLakeStorageAccountName_resource
    defaultDataLakeStorageAccountName_default_defaultDataLakeStorageFilesystemName
  ]
}

resource synapseWorkspace_allowAll 'Microsoft.Synapse/workspaces/firewallrules@2019-06-01-preview' = if (allowAllConnections) {
  // location: location
  name: '${synapseWorkspace_resource.name}/allowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource synapseWorkspace_sqlControl_default 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2019-06-01-preview' = {
  // location: location
  name: '${synapseWorkspace_resource.name}/default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: grantWorkspaceIdentityControlForSql
    }
  }
}

resource setWorkspaceIdRBACOnStorage  'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (setWorkspaceIdentityRbacOnStorageAccount) {
  name: workspaceStorageRBACName
  scope: defaultDataLakeStorageAccountName_resource 
  properties: {
    roleDefinitionId: '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)}'
    principalId: synapseWorkspace_resource.identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    synapseWorkspace_resource
    defaultDataLakeStorageAccountName_resource
  ]
}


resource defaultDataLakeStorageAccountName_Microsoft_Authorization_id_storageBlobDataContributorRoleID_userObjectId_storageRoleUniqueId 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (setSbdcRbacOnStorageAccount) {  //'Microsoft.Storage/storageAccounts/providers/roleAssignments@2020-04-01-preview' = if (setSbdcRbacOnStorageAccount) {
  name: userStorageRBACName
// name: '${defaultDataLakeStorageAccountName}/Microsoft.Authorization/${guid('${resourceGroup().id}/${storageBlobDataContributorRoleID}/${userObjectId}/${storageRoleUniqueId}')}'
  properties: {
    roleDefinitionId: '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)}'
    // roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleID)
    principalId: userObjectId
    principalType: 'User'
  }
  dependsOn: [
    synapseWorkspace_resource
    defaultDataLakeStorageAccountName_resource
  ]
}

/*
resource name_SetMsiBypass 'Microsoft.Storage/storageAccounts@2021-02-01' = if (setWorkspaceMsiByPassOnStorageAccount) {
  name: defaultDataLakeStorageAccountName
  location: storageLocation
  properties:workspaceStorageAccountProperties
}
*/

output resourceGroupName string = resourceGroup().name
output resourceGroupLocation string = location
output synapseWorkspaceName string = workspaceName
output defaultDataLakeStorageAccountName string = defaultDataLakeStorageAccountName
output synapseStorageString string = '${defaultDataLakeStorageAccountName}/Microsoft.Authorization/${guid('${resourceGroup().id}/${storageBlobDataContributorRoleID}/${workspaceName}/${storageRoleUniqueId}')}'
output webEndpoint string = webEndpoint
output devEndpoint string = devEndpoint
output ondemandEndpoint string = onDemandEndpoint
output sqlEndpoint string = sqlEndpoint
output synapsePrincipalId string = reference(synapseWorkspace_resource.id, '2019-06-01-preview','Full').identity.principalId
