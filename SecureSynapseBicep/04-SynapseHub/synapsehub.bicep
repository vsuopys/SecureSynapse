param nameHub string = 'hubsynapse'
param tagValues object = {}

var location = resourceGroup().location

resource nameHub_resource  'Microsoft.Synapse/privateLinkHubs@2021-03-01' = {
  name: nameHub
  location: location

  // identity: {
  //   type: 'None'
  // }
  properties: {}
  tags: tagValues
  dependsOn: []
}

output synapseHubName string = nameHub_resource.name
