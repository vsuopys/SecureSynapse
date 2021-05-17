//
//
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'rg-secsyn-bicep'
  location: deployment().location
}

//Vnet parameters
param pVnetName string = 'vnet-customer-bicep'
param pVnetAddressCidr string = '172.19.0.0/16'
param pDefaultSubnetCidr string = '172.19.0.0/26'
param pGatewaySubnetCidr string = '172.19.1.0/26'
param pPrivateEndpointSubnetCidr string = '172.19.2.0/26'
param pDataSubnetCidr string = '172.19.3.0/26'

// VM parameters
param pCreateJumpVm bool = true
param pVmName string = 'vm'
param vmAdminName string = 'cloudsa'
@secure()
param vmAdminPassword string

// Synapse parameters
param pCreateSynapseWs bool = true
param synapseAdminName string = 'adminuser'
@secure()
param synapseAdminPassword string
param pSynapseWsName string = 'secsynbic-ws'
param pAllowAllConnections bool = false
// userObjectId        // use this parameter to apply Storage Blob Contributor to a user on the Synapse storage account
param pCreateNewStorageAccount bool = true
param pStorageAccountName string = 'secbicdlac'
param pStorageFilesystemName string = 'synapsefilesystem'

// Generate unique names
var vUniqueSuffix = uniqueString(rg.name, deployment().name)
var vUniqueStorageAccount = '${pStorageAccountName}${vUniqueSuffix}'
var vUniqueVmName =  '${pVmName}${vUniqueSuffix}'
var vUniqueSynapseWsName = '${pSynapseWsName}-${vUniqueSuffix}'
var vUniqueVnetName = '${pVnetName}-${rg.name}'

module synapseVnets '01-Vnet/vnet.bicep' = {
  name: 'synapseVnets'
  scope: rg
  params: {
    virtualNetworks_vnet_name: vUniqueVnetName
    virtualNetwork_address_block: pVnetAddressCidr
    virtualNetwork_appsubnet_address_block: pPrivateEndpointSubnetCidr
    virtualNetwork_datasubnet_address_block: pDataSubnetCidr
    virtualNetwork_gateway_address_block: pGatewaySubnetCidr
    virtualNetwork_default_address_block: pDefaultSubnetCidr
    createJumpVm: pCreateJumpVm
  }
}

module synapseJumpVm '02-Vm/vm.bicep' = if (pCreateJumpVm) {
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

module synapseWorkspace '03-SynapseWs/synapsews.bicep' = if (pCreateSynapseWs) {
  name: 'synapseWorkspace'
  scope: resourceGroup('rg-test-bicep')
  params: {
    workspaceName: vUniqueSynapseWsName
    defaultDataLakeStorageAccountName: vUniqueStorageAccount
    defaultDataLakeStorageFilesystemName: pStorageFilesystemName
    sqlAdministratorLogin: synapseAdminName
    sqlAdministratorLoginPassword: synapseAdminPassword
    // userObjectId
    allowAllConnections: pAllowAllConnections
    isNewStorageAccount: pCreateNewStorageAccount
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: []
      preventDataExfiltration: true
    }
  }
}

module synapsePrivateLinkHub  '04-SynapseHub/synapsehub.bicep' = if (pCreateSynapseWs) {
  name: 'synapsePrivateLinkHub'
  scope: rg
  params: {
    nameHub: 'hub${replace(vUniqueSynapseWsName, '-', '')}'
  }
  dependsOn: [
    synapseWorkspace
  ]
}

module synapsePrivateEndpoint '05-SynapsePE/privateendpoints.bicep' = if (pCreateSynapseWs) {   //   '05-SynapsePE/synapsepe.bicep' = if (pCreateSynapseWs) {
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

output vmName string = vUniqueVmName
output vmSize string = reference('synapseJumpVm', '2019-05-01').outputs.vmSize.value
output vmAdminUsername string = reference('synapseJumpVm', '2019-05-01').outputs.adminUsername.value

output synapseWorkspaceName string = reference('synapseWorkspace', '2019-05-01').outputs.synapseWorkspaceName.value
output synapseWorkspaceURL string = reference('synapseWorkspace', '2019-05-01').outputs.webEndpoint.value
output synapseStorageAccount string = vUniqueStorageAccount
output synapseStorageString string = reference('synapseWorkspace', '2019-05-01').outputs.synapseStorageString.value
output synapseSQL string = reference('synapseWorkspace', '2019-05-01').outputs.sqlEndpoint.value
output synapseSqlOndemand string = reference('synapseWorkspace', '2019-05-01').outputs.ondemandEndpoint.value
output synapsePrincipalId string = reference('synapseWorkspace', '2019-05-01').outputs.synapsePrincipalId.value

output synapseHubName string = reference('synapsePrivateLinkHub', '2019-05-01').outputs.synapseHubName.value

output HubPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_HubPrivateEndpointName.value
output SqlPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_SqlPrivateEndpointName.value
output SqlOnDemandPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_SqlOnDemandPrivateEndpointName.value
output DevPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_DevPrivateEndpointName.value
