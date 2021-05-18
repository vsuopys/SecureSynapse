param virtualNetworks_vnet_name string
param virtualNetwork_address_block string
param virtualNetwork_appsubnet_address_block string
param virtualNetwork_datasubnet_address_block string
param virtualNetwork_gateway_address_block string
param virtualNetwork_default_address_block string
param createJumpVm bool

var subnet_datasubnet_name = 'datavm-sub'
var subnet_appsubnet_name = 'appvm-sub'
var networkSecurityGroups_appsubnet_name_var = 'nsg-appvm-sub'
var networkSecurityGroups_datasubnet_name_var = 'nsg-datavm-sub'
var location = resourceGroup().location


resource networkSecurityGroups_datasubnet_name 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroups_datasubnet_name_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP_Port_3389'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: virtualNetwork_datasubnet_address_block
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'HTTPS_Port_443'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: virtualNetwork_datasubnet_address_block
          access: 'Allow'
          priority: 310
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource networkSecurityGroups_appsubnet_name 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroups_appsubnet_name_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ARM-ServiceTag'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureResourceManager'
          access: 'Allow'
          priority: 3000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'FrontDoor-ServiceTag'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureFrontDoor.Frontend'
          access: 'Allow'
          priority: 3010
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AAD-ServiceTag'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 3020
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Monitor-ServiceTag'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 3030
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: virtualNetwork_appsubnet_address_block
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}


// Allow access to jumpbox via RDP if one is created
resource networkSecurityGroups_appsubnet_name_RDP 'Microsoft.Network/networkSecurityGroups/securityRules@2020-05-01' = if (createJumpVm) {
  name: '${networkSecurityGroups_appsubnet_name.name}/RDP'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: virtualNetwork_appsubnet_address_block
    access: 'Allow'
    priority: 300
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource virtualNetworks_vnet_name_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworks_vnet_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_address_block
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: virtualNetwork_default_address_block
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: virtualNetwork_gateway_address_block
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_appsubnet_name
        properties: {
          addressPrefix: virtualNetwork_appsubnet_address_block
          networkSecurityGroup: {
            id: networkSecurityGroups_appsubnet_name.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_datasubnet_name
        properties: {
          addressPrefix: virtualNetwork_datasubnet_address_block
          networkSecurityGroup: {
            id: networkSecurityGroups_datasubnet_name.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
  dependsOn:[
    networkSecurityGroups_appsubnet_name
  ]
}

output resourceGroupName string = resourceGroup().name
output resourceGroupID string = resourceGroup().id
output resourceGroupLocation string = resourceGroup().location
output virtualNetworkName string = virtualNetworks_vnet_name
output appSubnetName string = subnet_appsubnet_name
output dataSubnetName string = subnet_datasubnet_name
