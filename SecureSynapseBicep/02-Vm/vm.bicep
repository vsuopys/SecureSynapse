@description('The name of the VM')
@maxLength(15)
param virtualMachineName string = 'VM'

param networkSecurityGroupRules array = [
  {
    name: 'RDP'
    properties: {
      priority: 300
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  }
]
param subnetName string = 'appvm-sub'
param virtualNetworkName string
param publicIpAddressType string = 'Dynamic'
param publicIpAddressSku string = 'Basic'
param osDiskType string = 'StandardSSD_LRS'
param virtualMachineSize string = 'Standard_DS11_v2'
param adminUsername string = 'cloudsa'

@secure()
param adminPassword string

param patchMode string = 'AutomaticByOS'
param enableHotpatching bool = false
param autoShutdownStatus string = 'Enabled'
param autoShutdownTime string = '19:00'
param autoShutdownTimeZone string = 'Central Standard Time'
param autoShutdownNotificationStatus string = 'Disabled'
param autoShutdownNotificationLocale string = 'en'

var location = resourceGroup().location
var networkInterfaceName_var = '${virtualMachineName}-nic'
var networkSecurityGroupName_var = '${virtualMachineName}-nsg'
var publicIpAddressName_var = '${virtualMachineName}-ip'
var vnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}'
var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName_var)
var subnetRef = '${vnetId}/subnets/${subnetName}'
var aadLoginExtensionName = 'AADLoginForWindows'

// Allow RDP
resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource publicIpAddressName 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
  sku: {
    name: publicIpAddressSku
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2018-10-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName_var)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroupName
    publicIpAddressName
  ]
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: enableHotpatching
          patchMode: patchMode
        }
      }
    }
    licenseType: 'Windows_Client'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  identity: {
    type: 'SystemAssigned'  
  }
  dependsOn: [
    networkInterfaceName
  ]
}

resource shutdown_computevm_virtualMachineName 'Microsoft.DevTestLab/schedules@2018-09-15' = {  // 'Microsoft.DevTestLab/schedules@2017-04-26-preview' = {
  name: 'shutdown-computevm-${virtualMachineName}'
  location: location
  properties: {
    status: autoShutdownStatus
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    targetResourceId: virtualMachineName_resource.id
    notificationSettings: {
      status: autoShutdownNotificationStatus
      notificationLocale: autoShutdownNotificationLocale
      timeInMinutes: 30  // '30'
    }
  }
  dependsOn: [
    virtualMachineName_resource
  ]
}

resource virtualMachineName_aadLoginExtensionName 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  name: '${virtualMachineName_resource.name}/${aadLoginExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: aadLoginExtensionName
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
  dependsOn: [
    virtualMachineName_resource
  ]
}

output vmName string = virtualMachineName
output vmSize string = virtualMachineSize
output adminUsername string = adminUsername
