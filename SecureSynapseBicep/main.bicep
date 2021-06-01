//
//
param resourceGroupName string = 'rg-secsyn-bicep'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: deployment().location
}

//Vnet parameters
param vnetName string = 'vnet-customer-bicep'
param vnetAddressCidr string = '172.19.0.0/16'
param defaultSubnetCidr string = '172.19.0.0/26'
param gatewaySubnetCidr string = '172.19.1.0/26'
param privateEndpointSubnetCidr string = '172.19.2.0/26'
param dataSubnetCidr string = '172.19.3.0/26'

// VM parameters
param createJumpVm bool = true
param vmName string = 'vm'
param vmAdminName string = 'cloudsa'
@secure()
param vmAdminPassword string

// Synapse parameters
param createSynapseWs bool = true
param synapseAdminName string = 'adminuser'
@secure()
param synapseAdminPassword string
param synapseWsName string = 'secsynbic-ws'
param allowAllConnections bool = false
// userObjectId        // use this parameter to apply Storage Blob Contributor to a user on the Synapse storage account
param createNewStorageAccount bool = true
param workspaceIdentityRbacOnStorageAccount bool = true
param storageAccountName string = 'secbicdlac'
param storageFilesystemName string = 'synapsefilesystem'

// Generate unique names
var vUniqueSuffix = uniqueString(rg.name, deployment().name)
var vUniqueStorageAccount = '${storageAccountName}${vUniqueSuffix}'
var vUniqueVmName =  '${vmName}${vUniqueSuffix}'
var vUniqueSynapseWsName = '${synapseWsName}-${vUniqueSuffix}'
var vUniqueVnetName = '${vnetName}-${rg.name}'

module synapseVnets '01-Vnet/vnet.bicep' = {
  name: 'synapseVnets'
  scope: rg
  params: {
    virtualNetworks_vnet_name: vUniqueVnetName
    virtualNetwork_address_block: vnetAddressCidr
    virtualNetwork_appsubnet_address_block: privateEndpointSubnetCidr
    virtualNetwork_datasubnet_address_block: dataSubnetCidr
    virtualNetwork_gateway_address_block: gatewaySubnetCidr
    virtualNetwork_default_address_block: defaultSubnetCidr
    createJumpVm: createJumpVm
  }
}

module synapseJumpVm '02-Vm/vm.bicep' = if (createJumpVm) {
  name: 'synapseJumpVm'
  scope: rg
  params: {
    virtualMachineName: vUniqueVmName
    virtualNetworkName: reference('synapseVnets').outputs.virtualNetworkName.value
    subnetName: reference('synapseVnets').outputs.appSubnetName.value
    adminUsername: vmAdminName
    adminPassword: vmAdminPassword
  }
  dependsOn: [
    synapseVnets
  ]
}

module synapseWorkspace '03-SynapseWs/synapsews.bicep' = if (createSynapseWs) {
  name: 'synapseWorkspace'
  scope: resourceGroup(rg.name)
  params: {
    workspaceName: vUniqueSynapseWsName
    defaultDataLakeStorageAccountName: vUniqueStorageAccount
    defaultDataLakeStorageFilesystemName: storageFilesystemName
    sqlAdministratorLogin: synapseAdminName
    sqlAdministratorLoginPassword: synapseAdminPassword
    // userObjectId
    allowAllConnections: allowAllConnections
    isNewStorageAccount: createNewStorageAccount
    setWorkspaceIdentityRbacOnStorageAccount: workspaceIdentityRbacOnStorageAccount
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: []
      preventDataExfiltration: true
    }
  }
}

module synapsePrivateLinkHub  '04-SynapseHub/synapsehub.bicep' = if (createSynapseWs) {
  name: 'synapsePrivateLinkHub'
  scope: rg
  params: {
    nameHub: 'hub${replace(vUniqueSynapseWsName, '-', '')}'
  }
  dependsOn: [
    synapseWorkspace
  ]
}

module synapsePrivateEndpoint '05-SynapsePE/privateendpoints.bicep' = if (createSynapseWs) {   //   '05-SynapsePE/synapsepe.bicep' = if (createSynapseWs) {
  name: 'synapsePrivateEndpoint'
  scope: rg
  params: {
    p_HubPrivateEndpointName: 'hub-${vUniqueSynapseWsName}-pe'
    p_HubPrivateLinkResource: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.Synapse/privateLinkHubs/${reference('synapsePrivateLinkHub', '2019-05-01').outputs.synapseHubName.value}'
    p_SqlPrivateEndpointName: 'sql-${vUniqueSynapseWsName}-pe'
    p_SqlPrivateLinkResource: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.Synapse/workspaces/${reference('synapseWorkspace', '2019-05-01').outputs.synapseWorkspaceName.value}'
    p_SqlOnDemandPrivateEndpointName: 'sqlondemand-${vUniqueSynapseWsName}-pe'
    p_DevPrivateEndpointName: 'dev-${vUniqueSynapseWsName}-pe'
    p_Subnet: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.Network/virtualNetworks/${vUniqueVnetName}/subnets/appvm-sub'
    p_VirtualNetworkId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${rg.name}/providers/Microsoft.Network/virtualNetworks/${vUniqueVnetName}'
  }
  dependsOn: [
    synapsePrivateLinkHub
  ]
}

output vmName string = createJumpVm ? vUniqueVmName : 'N/A'
output vmSize string = createJumpVm ? reference('synapseJumpVm', '2019-05-01').outputs.vmSize.value : 'N/A'
output vmAdminUsername string = createJumpVm ? reference('synapseJumpVm', '2019-05-01').outputs.adminUsername.value : 'N/A'

output synapseWorkspaceName string = createSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.synapseWorkspaceName.value : 'N/A'
output synapseWorkspaceURL string = createSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.webEndpoint.value : 'N/A'
output synapseStorageAccount string = createSynapseWs ? vUniqueStorageAccount : 'N/A'
output synapseStorageString string = createSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.synapseStorageString.value : 'N/A'
output synapseSQL string = createSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.sqlEndpoint.value : 'N/A'
output synapseSqlOndemand string = createSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.ondemandEndpoint.value : 'N/A'
output synapsePrincipalId string = createSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.synapsePrincipalId.value : 'N/A'

output synapseHubName string = reference('synapsePrivateLinkHub', '2019-05-01').outputs.synapseHubName.value

output HubPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_HubPrivateEndpointName.value
output SqlPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_SqlPrivateEndpointName.value
output SqlOnDemandPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_SqlOnDemandPrivateEndpointName.value
output DevPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_DevPrivateEndpointName.value
