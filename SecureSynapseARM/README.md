# SecureSynapseARM Structure

This project consists of a driver ARM template that is linked to a number of scoped ARM templates as listed:

01-Vnet

02-JumpVM

03-SynapseWS

04-PrivateLinkHub

05-PrivateEndpoints

# Prerequisites
You must have an existing resource group which will be used for all deployments. Note that Synapse creates a managed resource group as part of the deployment process. The managed resource group is not alway cleaned up if you delete your own resource group.

## Secure Credentials
In order to avoid storing passwords in the templates, you must pass a password secure string as a Powershell cmdlet parameter as shown below:

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

# Post Deployment Requirements
1. The jumpbox VM is configured to use AAD authentication. You will need to add yourself to the "Virtual Machine User Login" or "Virtual Machine Administrator Login" roles for this VM or you will not be able to log in with you AAD credentials.
2. You will need to configure the jumpbox VM with Microsoft endpoint protection. On the VM, go to "Settings/Account/Access Work or School". Disconnect from Microsoft Azure AD, reboot, and re-login as the local administrator account. Go back to "Settings/Account/Access Work or School" and add a new connection to Microsoft Azure AD with your Microsoft account. This will register the VM with Microsoft endpoint protection.
3. (Optional) It would be best practice to enable just in time access through the Azure Portal for this VM. You may be prompted for VPN and disk encryption which are optional.

# Example Calls

1. From Powershell
    a. Clone or download the Github repo from https://github.com/vsuopys/SecureSynapseARM
    b. Switch directory to the lowest SecureSynapseARM folder
    c. run the following commands:
        - $sqlvmpassword = ConvertTo-SecureString "your-sqlvm-password" -AsPlainText -Force
        - $sqlpassword = ConvertTo-SecureString "your-Synapse-password" -AsPlainText -Force
        - New-AzConnection
        - New-AzResourceGroupDeployment -ResourceGroupName "your-resource-group" -Name "your-deployment-name" -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters.json -adminUsername "your-sqlvm-admin-user" -adminPassword $sqlvmpassword -sqlAdminLogin "your-Synapse-admin-user" -sqlAdminPassword $sqlpassword

# Notes
The main ARM template (azuredeploy.json) references several linked templates that are stored in a read only Azure blob account. If you wish to modify these linked templates then you will need to change the main ARM template to point to your local version.
