# SecureSynapseARM

This project consists of a driver ARM template that is linked to a number of scoped ARM templates as listed:

01-vnet

02-jumpbox

03-xxx

04-yyy

# Secure Credentials
In order to avoid storing passwords in the templates, you must pass a password secure string as a Powershell cmdlet parameter as shown below:

$mypassword = ConvertTo-SecureString "your-password" `
                -AsPlainText `
                -Force

New-AzureRmResourceGroupDeployment
    -ResourceGroupName "your-resource-group"
    -TemplateFile azuredeploy.json
    -TemplateParameterFile azuredeploy.parameters.json
    -adminUsername "your-admin-user"
    -adminPassword $mypassword
