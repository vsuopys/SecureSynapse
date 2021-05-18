//
//
param resourceGroupName string = 'rg-secsyn-bicep'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: deployment().location
}

//Vnet parameters
param VnetName string = 'vnet-customer-bicep'
param VnetAddressCidr string = '172.19.0.0/16'
param DefaultSubnetCidr string = '172.19.0.0/26'
param GatewaySubnetCidr string = '172.19.1.0/26'
param PrivateEndpointSubnetCidr string = '172.19.2.0/26'
param DataSubnetCidr string = '172.19.3.0/26'

// VM parameters
param CreateJumpVm bool = true
param VmName string = 'vm'
param vmAdminName string = 'cloudsa'
@secure()
param vmAdminPassword string

// Synapse parameters
param CreateSynapseWs bool = true
param synapseAdminName string = 'adminuser'
@secure()
param synapseAdminPassword string
param SynapseWsName string = 'secsynbic-ws'
param AllowAllConnections bool = false
// userObjectId        // use this parameter to apply Storage Blob Contributor to a user on the Synapse storage account
param CreateNewStorageAccount bool = true
param WorkspaceIdentityRbacOnStorageAccount bool = true
param StorageAccountName string = 'secbicdlac'
param StorageFilesystemName string = 'synapsefilesystem'

// Generate unique names
var vUniqueSuffix = uniqueString(rg.name, deployment().name)
var vUniqueStorageAccount = '${StorageAccountName}${vUniqueSuffix}'
var vUniqueVmName =  '${VmName}${vUniqueSuffix}'
var vUniqueSynapseWsName = '${SynapseWsName}-${vUniqueSuffix}'
var vUniqueVnetName = '${VnetName}-${rg.name}'

module synapseVnets '01-Vnet/vnet.bicep' = {
  name: 'synapseVnets'
  scope: rg
  params: {
    virtualNetworks_vnet_name: vUniqueVnetName
    virtualNetwork_address_block: VnetAddressCidr
    virtualNetwork_appsubnet_address_block: PrivateEndpointSubnetCidr
    virtualNetwork_datasubnet_address_block: DataSubnetCidr
    virtualNetwork_gateway_address_block: GatewaySubnetCidr
    virtualNetwork_default_address_block: DefaultSubnetCidr
    createJumpVm: CreateJumpVm
  }
}

module synapseJumpVm '02-Vm/vm.bicep' = if (CreateJumpVm) {
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

module synapseWorkspace '03-SynapseWs/synapsews.bicep' = if (CreateSynapseWs) {
  name: 'synapseWorkspace'
  scope: resourceGroup(rg.name)
  params: {
    workspaceName: vUniqueSynapseWsName
    defaultDataLakeStorageAccountName: vUniqueStorageAccount
    defaultDataLakeStorageFilesystemName: StorageFilesystemName
    sqlAdministratorLogin: synapseAdminName
    sqlAdministratorLoginPassword: synapseAdminPassword
    // userObjectId
    allowAllConnections: AllowAllConnections
    isNewStorageAccount: CreateNewStorageAccount
    setWorkspaceIdentityRbacOnStorageAccount: WorkspaceIdentityRbacOnStorageAccount
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: []
      preventDataExfiltration: true
    }
  }
}

module synapsePrivateLinkHub  '04-SynapseHub/synapsehub.bicep' = if (CreateSynapseWs) {
  name: 'synapsePrivateLinkHub'
  scope: rg
  params: {
    nameHub: 'hub${replace(vUniqueSynapseWsName, '-', '')}'
  }
  dependsOn: [
    synapseWorkspace
  ]
}

module synapsePrivateEndpoint '05-SynapsePE/privateendpoints.bicep' = if (CreateSynapseWs) {   //   '05-SynapsePE/synapsepe.bicep' = if (CreateSynapseWs) {
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

output vmName string = CreateJumpVm ? vUniqueVmName : 'N/A'
output vmSize string = CreateJumpVm ? reference('synapseJumpVm', '2019-05-01').outputs.vmSize.value : 'N/A'
output vmAdminUsername string = CreateJumpVm ? reference('synapseJumpVm', '2019-05-01').outputs.adminUsername.value : 'N/A'

output synapseWorkspaceName string = CreateSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.synapseWorkspaceName.value : 'N/A'
output synapseWorkspaceURL string = CreateSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.webEndpoint.value : 'N/A'
output synapseStorageAccount string = CreateSynapseWs ? vUniqueStorageAccount : 'N/A'
output synapseStorageString string = CreateSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.synapseStorageString.value : 'N/A'
output synapseSQL string = CreateSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.sqlEndpoint.value : 'N/A'
output synapseSqlOndemand string = CreateSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.ondemandEndpoint.value : 'N/A'
output synapsePrincipalId string = CreateSynapseWs ? reference('synapseWorkspace', '2019-05-01').outputs.synapsePrincipalId.value : 'N/A'

output synapseHubName string = reference('synapsePrivateLinkHub', '2019-05-01').outputs.synapseHubName.value

output HubPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_HubPrivateEndpointName.value
output SqlPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_SqlPrivateEndpointName.value
output SqlOnDemandPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_SqlOnDemandPrivateEndpointName.value
output DevPrivateEndpointName string = reference('synapsePrivateEndpoint', '2019-05-01').outputs.o_DevPrivateEndpointName.value
