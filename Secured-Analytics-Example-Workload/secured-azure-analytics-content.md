Analytic systems often involve the gathering and sharing of sensitive information. It is vital to prevent sensitive information from being exposed on the public internet during the normal course of data processing - from source system to end user. This sample architecture shows the components and steps necessary to ensure data landed into in a Synapse analytic environment traverses the Azure backbone network exclusively:

- Visualization tools can only access Synapse from within the Azure network
- The Synapse Studio user interface will only render data when accessed from within the Azure network
- Synapse accesses data residing in Azure Data Lake Storage via the Azure network
- Synapse [data exfiltration prevention](/azure/synapse-analytics/security/workspace-data-exfiltration-protection) can be enabled

## Potential use cases

This is a baseline Synapse infrastructure deployment that creates the foundation to deploy additional data components such as Cosmos DB and Power BI in a secured Synapse network environment. This example can be used in many industries such as financial services, healthcare, retail, and manufacturing.

## Architecture

![Deployed Architecture](SecuredSynapseinfrastructure.png?raw=true "Architecture")

This architecture leverages the Azure backbone network to route traffic from Synapse to the relevant data sources and targets, avoiding public internet traffic. Customers will need to access the Synapse Studio user interface from an Azure private network in order to see data.  Applications will only be able to connect to Synapse databases from an Azure private network. Synapse background processing (Spark and integration runtime) will also route traffic over the Azure backbone network. Optionally, a VM can be created on the private endpoint Vnet to facilitate testing of full data access in the Synapse Studio UI.

### Components

- [Azure Synapse Analytics](https://azure.microsoft.com/services/synapse-analytics/) provides multiple data processing engines (SQL and Spark) along with integration services.
- [Azure Data Lake Storage](https://azure.microsoft.com/services/storage/data-lake-storage/) provides storage for any type of file.
- [Azure Key Vault](https://azure.microsoft.com/services/key-vault/) provides a secure means of storing credential and secrets.
- [Azure Private Link](https://azure.microsoft.com/services/private-link/#overview) enables communication between Azure services over the Azure backbone network.
- [Azure Virtual Network](https://azure.microsoft.com/services/virtual-network/) provides an extension of the customer network into Azure.
- [Azure DNS](https://azure.microsoft.com/services/dns/#features) provides IP address resolution for Azure resources.
- [Azure Resource Manager Templates](https://azure.microsoft.com/services/arm-templates/) are the mechanism for automating the deployment of Azure resources via a template file.

### Data Flow

The data flows through the solution as follows:

1. Users and applications can access data from the Synapse structured data (SQL pools) by accessing the appropriate private endpoints connected to the customer Azure Vnet. Users can also work interactively with the Synapse Studio UI when connected to this Vnet.

1. Synapse background processes such as Spark jobs and integration activities connect to Azure services via Managed Private Endpoints. Data is typically ingested into Synapse using these background processes. The ingested data is then stored in a Azure Data Lake Storage (#3) or a provisioned Synapse SQL data warehouse (#4). Using a self-hosted integration runtime, you can also manage and run copy activities between a data store in your on-premises environment and the cloud. Note that this template does not deploy a self hosted integration runtime.

1. Azure Data Lake Storage Gen2 provides secure storage that can be accessed via the SQL or Spark data processing engines.

1. Relational data can be stored in a Synapse SQL data warehouse for easy consumption by visualization tools like Power BI.  

1. Firewalls and network security rules limit access on storage accounts, SQL databases, Spark engines, and the Synapse Studio UI.

## Considerations

This template only deploys the core Synapse capabilities and does not take into account the network configurations necessary to connect an on premises data center to Azure. Users of this template are expected to configure the VPN Gateway and Express Route on their own. In addition, there are many data sources that can be integrated into Synapse. This template only addresses one, Azure Data Lake Storage (Gen2).

### Security

Data security is strongest by implementing many layers of protection. This example focuses only one layer... the network route data takes as it moves through Synapse components. There are many others to consider including, but not limited to:

- Encrypting data at rest and over the network
- Following *least privilege principle* using role based access controls at both Azure and Synapse levels
- Auditing user activity
- Protecting keys and secrets
- Ensuring secure source system connectivity

After deploying this template, users will still be able to authenticate into the Synapse Studio user interface over the public internet. However, those users will be blocked from accessing any data. In order to see data, users need to access the Synapse Studio UI from a private Azure network.

## Deploy this scenario

You can deploy the ARM template [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvsuopys%2FSecureSynapse%2Fmaster%2FSecureSynapseARM%2Fazuredeploy.json)

Or, you can explore the templates by visiting the [Github repository](https://github.com/vsuopys/SecureSynapse).

### Post deployment requirements

1. A jumpbox VM is (optionally) created to provide a way to access data within the Synapse workspace. The VM is configured to use AAD authentication. You will need to add yourself to the Azure *"Virtual Machine User Login" or "Virtual Machine Administrator Login"* RBAC roles for this VM or you will not be able to log in with your AAD credentials.
1. Make sure the jumpbox Windows OS is fully updated.
1. Manually create a private endpoint for the default Synapse data lake account in the "privateEndpointSubnet". This will allow Synapse Studio to see files in the storage account.
1. Manually create a **managed** private endpoint for the default Synapse data lake account through Synapse Studio. This will allow Synapse background processes to see files in the storage account.
1. (Optional) It would be best practice to enable just in time access through the Azure Portal for this VM. You may be prompted for VPN and disk encryption which are optional.

## Next steps

To learn how to further develop this approach, learn the basics of Azure Synapse Analytics by completing the following tutorials:

- [Get Started with Azure Synapse Analytics](/azure/synapse-analytics/get-started)

- [Tutorial: Explore and Analyze data lakes with serverless SQL pool](/azure/synapse-analytics/sql/tutorial-data-analyst)

- [Analyze data in a storage account](/azure/synapse-analytics/get-started-analyze-storage)

- [Analyze data with dedicated SQL pools](/azure/synapse-analytics/get-started-analyze-sql-pool)

- [Integrate with pipelines](/azure/synapse-analytics/get-started-pipelines)

## Related resources

Refer to these articles when planning and deploying solutions using Azure Synapse Analytics:

- [Security baseline for Synapse dedicated SQL pool](/security/benchmark/azure/baselines/synapse-analytics-security-baseline?toc=/azure/synapse-analytics/toc.json)

- [Data exfiltration protection for Azure Synapse Analytics workspaces](/azure/synapse-analytics/security/workspace-data-exfiltration-protection)

- [Azure Synapse Analytics IP firewall rules](/azure/synapse-analytics/security/synapse-workspace-ip-firewall)

- [Azure Synapse Analytics Managed Virtual Network](/azure/synapse-analytics/security/synapse-workspace-managed-vnet)

- [Synapse Managed private endpoints](/azure/synapse-analytics/security/synapse-workspace-managed-private-endpoints)

- [Configure Azure Storage firewalls and virtual networks](/azure/storage/common/storage-network-security?tabs=azure-portal)

- [Connect to Azure Synapse Studio using Azure Private Link Hubs](/azure/synapse-analytics/security/synapse-private-link-hubs)

- [Connect to a secure Azure storage account from your Synapse workspace](/azure/synapse-analytics/security/connect-to-a-secure-storage-account)

- [Use Azure Active Directory Authentication for authentication with Synapse SQL](/azure/synapse-analytics/sql/active-directory-authentication)
