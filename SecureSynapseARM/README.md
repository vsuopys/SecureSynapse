# SecureSynapseARM Structure

This project consists of a driver ARM template that is linked to a number of scoped ARM templates as listed:

* 01-Vnet

* 02-JumpVM

* 03-SynapseWS

* 04-PrivateLinkHub

* 05-PrivateEndpoints

The resulting deployment looks like this:



# Prerequisites
You must have an existing resource group which will be used for all deployments. Note that Synapse creates a managed resource group as part of the deployment process. The managed resource group is not alway cleaned up if you delete your own resource group.

## Secure Credentials
In order to avoid storing passwords in the templates, you must pass a password secure string as a Powershell cmdlet parameter as shown below:
```powershell
$sqlvmpassword = ConvertTo-SecureString "your-sqlvm-password" -AsPlainText -Force

$sqlpassword = ConvertTo-SecureString "your-Synapse-password" -AsPlainText -Force

New-AzResourceGroupDeployment
    -ResourceGroupName "your-resource-group"
    -TemplateFile azuredeploy.json
    -TemplateParameterFile azuredeploy.parameters.json
    -adminUsername "your-sqlvm-admin-user"
    -adminPassword $sqlvmpassword
    -sqlAdminLogin "your-Synapse-admin-user"
    -sqlAdminPassword $sqlpassword
```

Template parameters specified on the command line will overwrite the defaults in the template.

# Post Deployment Requirements
1. The jumpbox VM is configured to use AAD authentication. You will need to add yourself to the "Virtual Machine User Login" or "Virtual Machine Administrator Login" roles for this VM or you will not be able to log in with you AAD credentials.
2. You will need to configure the jumpbox VM with Microsoft endpoint protection. On the VM, go to "Settings/Account/Access Work or School". Disconnect from Microsoft Azure AD, reboot, and re-login as the local administrator account. Go back to "Settings/Account/Access Work or School" and add a new connection to Microsoft Azure AD with your Microsoft account. This will register the VM with Microsoft endpoint protection.
3. (Optional) It would be best practice to enable just in time access through the Azure Portal for this VM. You may be prompted for VPN and disk encryption which are optional.

# Example Calls

## Powershell
Clone or download the Github repo from https://github.com/vsuopys/SecureSynapseARM

Switch directory to the lowest SecureSynapseARM folder

Run the following commands:

```powershell
$sqlvmpassword = ConvertTo-SecureString "your-sqlvm-password" -AsPlainText -Force

$sqlpassword = ConvertTo-SecureString "your-Synapse-password" -AsPlainText -Force

Connect-AzAccount

New-AzResourceGroupDeployment -ResourceGroupName "your-resource-group" -Name "your-deployment-name" -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters.json -adminUsername "your-sqlvm-admin-user" -adminPassword $sqlvmpassword -sqlAdminLogin "your-Synapse-admin-user" -sqlAdminPassword $sqlpassword
```

# Notes
The main ARM template (azuredeploy.json) references several linked templates that are stored in a read only Azure blob account. If you wish to modify these linked templates then you will need to change the main ARM template to point to your local version.

# Parameter Specifications
```json
{
    "virtualNetworks_vnet_name": {
      "defaultValue": "vnet-customer",
      "type": "String"
    },
    "virtualNetwork_address_block": {
      "defaultValue": "172.17.0.0/16",
      "type": "string"
    },
    "virtualNetwork_appsubnet_address_block": {
      "defaultValue": "172.17.3.0/26",
      "type": "string"
    },
    "virtualNetwork_datasubnet_address_block": {
      "defaultValue": "172.17.2.0/26",
      "type": "string"
    },
    "virtualNetwork_gateway_address_block": {
      "defaultValue": "172.17.1.0/26",
      "type": "string"
    },
    "virtualNetwork_default_address_block": {
      "defaultValue": "172.18.0.0/26",
      "type": "string"
    },
    "createJumpVM": {
      "type": "String",
      "defaultValue": "false",
      "metadata": {
        "description": "Create a jumpbox VM?"
      }
    },
    "virtualMachineName": {
        "type": "String",
        "defaultValue": "vm",    // can only be 2 characters because of unique string added to end
        "metadata": {
          "description": "The name of the VM"
        }
    },
    "adminUsername": {
      "type": "String",
      "defaultValue": "cloudsa",
      "metadata": {
        "description": "The admin user name of the VM"
      }
    },
    "adminPassword": {
      "type": "SecureString",
      "minLength": 12,
      "defaultValue": "Thisisnotmypwd!",
      "metadata": {
        "description": "The admin password of the VM, 12 characters minimum"
      }
    },
    "createSynapseWS": {
      "type": "String",
      "defaultValue": "true",
      "metadata": {
        "description": "Create new Synapse workspace."
      }
    },
    "createNewStorageAccount": {
      "type": "String",
      "defaultValue": "true",
      "metadata": {
        "description": "Create new data lake storage account for Synapse metadata."
      }
    },
    "dataLakeAccount": {
      "type": "string",
      "defaultValue": "secsyndlac",
      "metadata": {
        "description": "Name of the data lake storage account for Synapse metadata."
      }
    },
    "dataLakeAccountContainer": {
      "type": "string",
      "defaultValue": "synapsefilesystem",
      "metadata": {
        "description": "Name of the data lake filesystem for Synapse metadata."
      }
    },
    "synapseWSName": {
      "type": "string",
      "defaultValue": "secsynapse-ws",
      "metadata": {
        "description": "Name of the Synapse workspace."
      }
    },
    "allowAllConnections": {
      "type": "String",
      "defaultValue": "true",
      "metadata": {
        "description": "Name of the data lake storage account for Synapse metadata."
      }
    },
    "sqlAdminLogin": {
      "type": "string",
      "defaultValue": "sqladminuser",
      "metadata": {
          "description": "Synapse SQL administrator account name"
      }
    },
    "sqlAdminPassword": {
      "type": "securestring",
      "metadata": {
          "description": "description"
      }
    }
}
```



virtualNetworks_vnet_name:
    type: String
    defaultValue: vnet-customer

virtualNetwork_address_block:
    type: String
    defaultValue: 172.17.0.0/16

virtualNetwork_appsubnet_address_block:
    type: String
    defaultValue: 172.17.3.0/26

virtualNetwork_datasubnet_address_block:
    type: String
    defaultValue: 172.17.2.0/26

virtualNetwork_gateway_address_block:
    type: String
    defaultValue: 172.17.1.0/26

virtualNetwork_default_address_block:
    type: String
    defaultValue: 172.17.0.0/26

createJumpVM:
    type: Bool
    defaultValue: false

virtualMachineName:
    type: String
    defaultValue: vm

adminUsername:
    type: String
    defaultValue: cloudsa

adminPassword:
    type: secureString
    defaultValue: null          // pass in parameter value from command line

createSynapseWS:
    type: Bool
    defaultValue: true

createNewStorageAccount:
    type: Bool
    defaultValue: true

dataLakeAccount:
    type: String
    defaultValue: secsyndlac

dataLakeAccountContainer:
    type: String
    defaultValue: synapsefilesystem

synapseWSName:
    type: String
    defaultValue: secsynapse-ws     // a unique hash based on resource group and deployment name will be appended

allowAllConnections:
    type: Bool
    defaultValue: false     // controls access from public internet

sqlAdminLogin:
    type: String
    defaultValue: sqladminuser

sqlAdminPassword:
    type: secureString
    defaultValue: null      //  pass in parameter value from command line
