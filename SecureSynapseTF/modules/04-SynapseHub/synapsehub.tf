variable hubName {
  type        = string
  default     = "hubsynapse"
  description = "description"
}

variable tagValues {
  type        = object
  default     = {}
  description = "description"
}

variable location {
  type        = string
  default     = "East US"
  description = "description"
}

resource "hubName_resource" {
  name: var.hubName
  location: var.location

  // identity: {
  //   type: 'None'
  // }
  properties: {}
  tags: var.tagValues
  depends_on: []
}

# output synapseHubName string = hubName_resource.name