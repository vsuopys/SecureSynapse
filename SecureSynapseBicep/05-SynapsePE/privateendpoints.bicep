param p_HubPrivateEndpointName string = 'hub-pe'
param p_SqlPrivateEndpointName string = 'sql-pe'
param p_SqlOnDemandPrivateEndpointName string = 'sqlondemand-pe'
param p_DevPrivateEndpointName string = 'dev-pe'
param p_HubPrivateLinkResource string
param p_SqlPrivateLinkResource string

param p_Subnet string
param p_VirtualNetworkId string
param p_Timestamp string = replace(replace(replace(utcNow(), ':', ''), ' ', ''), '/', '')

var v_Location = resourceGroup().location

//
// Create the Private Endpoints
//
resource hubPrivateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-03-01' = {
  location: v_Location
  name: p_HubPrivateEndpointName
  properties: {
    subnet: {
      id: p_Subnet
    }
    privateLinkServiceConnections: [
      {
        name: p_HubPrivateEndpointName
        properties: {
          privateLinkServiceId: p_HubPrivateLinkResource
          groupIds: [
            'Web'
          ]
        }
      }
    ]
  }
  tags: {}
}

resource sqlPrivateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-03-01' = {
  location: v_Location
  name: p_SqlPrivateEndpointName
  properties: {
    subnet: {
      id: p_Subnet
    }
    privateLinkServiceConnections: [
      {
        name: p_SqlPrivateEndpointName
        properties: {
          privateLinkServiceId: p_SqlPrivateLinkResource
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
  tags: {}
}

resource sqlOnDemandPrivateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-03-01' = {
  location: v_Location
  name: p_SqlOnDemandPrivateEndpointName
  properties: {
    subnet: {
      id: p_Subnet
    }
    privateLinkServiceConnections: [
      {
        name: p_SqlOnDemandPrivateEndpointName
        properties: {
          privateLinkServiceId: p_SqlPrivateLinkResource
          groupIds: [
            'SqlOnDemand'
          ]
        }
      }
    ]
  }
  tags: {}
}

resource devPrivateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-03-01' = {
  location: v_Location
  name: p_DevPrivateEndpointName
  properties: {
    subnet: {
      id: p_Subnet
    }
    privateLinkServiceConnections: [
      {
        name: p_DevPrivateEndpointName
        properties: {
          privateLinkServiceId: p_SqlPrivateLinkResource
          groupIds: [
            'Dev'
          ]
        }
      }
    ]
  }
  tags: {}
}

//
// Create the DNS zones
//
resource PrivateDnsZone_Hub_resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azuresynapse.net'
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    hubPrivateEndpointName_resource
  ]
}

resource PrivateDnsZone_Sql_resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.sql.azuresynapse.net'
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    sqlPrivateEndpointName_resource
  ]
}

resource PrivateDnsZone_Dev_resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.dev.azuresynapse.net'
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    devPrivateEndpointName_resource
  ]
}

//
// Create the DNS zone groups
//
resource dnsZoneGroup_Hub_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${p_HubPrivateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azuresynapse-net'
        properties: {
          privateDnsZoneId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/privatelink.azuresynapse.net'
        }
      }
    ]
  }
  dependsOn: [
    hubPrivateEndpointName_resource
    PrivateDnsZone_Hub_resource
  ]
}

resource dnsZoneGroup_Sql_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${p_SqlPrivateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-sql-azuresynapse-net'
        properties: {
          privateDnsZoneId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net'
        }
      }
    ]
  }
  dependsOn: [
    sqlPrivateEndpointName_resource
    PrivateDnsZone_Sql_resource
  ]
}

resource dnsZoneGroup_SqlOnDemand_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${p_SqlOnDemandPrivateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-sqlondemand-azuresynapse-net'
        properties: {
          privateDnsZoneId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net'
        }
      }
    ]
  }
  dependsOn: [
    sqlOnDemandPrivateEndpointName_resource
    PrivateDnsZone_Sql_resource
  ]
}

resource dnsZoneGroup_Dev_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${p_DevPrivateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-dev-azuresynapse-net'
        properties: {
          privateDnsZoneId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net'
        }
      }
    ]
  }
  dependsOn: [
    devPrivateEndpointName_resource
    PrivateDnsZone_Dev_resource
  ]
}
//
// Link private DNS zones to Vnet
//
resource virtualNetworkLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${PrivateDnsZone_Hub_resource.name}/${PrivateDnsZone_Hub_resource.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_VirtualNetworkId
    }
  }
  dependsOn: [
    PrivateDnsZone_Hub_resource
  ]
}

resource virtualNetworkLinkSql 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${PrivateDnsZone_Sql_resource.name}/${PrivateDnsZone_Sql_resource.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_VirtualNetworkId
    }
  }
  dependsOn: [
    PrivateDnsZone_Sql_resource
  ]
}
/*
resource virtualNetworkLinkSqlOnDemand 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${PrivateDnsZone_Sql_resource.name}/${PrivateDnsZone_Sql_resource.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: p_VirtualNetworkId
    }
  }
  dependsOn: [
    PrivateDnsZone_Sql_resource
  ]
}
*/
resource virtualNetworkLinkDev 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${PrivateDnsZone_Dev_resource.name}/${PrivateDnsZone_Dev_resource.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_VirtualNetworkId
    }
  }
  dependsOn: [
    PrivateDnsZone_Dev_resource
  ]
}


output o_HubPrivateEndpointName string = p_HubPrivateEndpointName
output o_SqlPrivateEndpointName string = p_SqlPrivateEndpointName
output o_SqlOnDemandPrivateEndpointName string = p_SqlOnDemandPrivateEndpointName
output o_DevPrivateEndpointName string = p_DevPrivateEndpointName
