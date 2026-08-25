# Azure Bastion Lab

Infrastructure as Code (IaC) project for deploying **Azure Bastion and supporting Azure resources using Bicep**.

This project demonstrates how to design, organize, validate, and deploy an Azure Bastion environment using **modular Bicep templates**, **environment-specific parameter files**, Azure CLI, Git, and GitHub.

---

## 📌 Project Overview

The purpose of this project is to deploy an Azure environment where virtual machines can be accessed securely through **Azure Bastion** without requiring a public IP address directly on the virtual machines.

The infrastructure is defined using **Bicep**, Microsoft's domain-specific language for deploying Azure resources declaratively.

Instead of manually creating each resource through the Azure Portal, the infrastructure is defined as reusable code.

The project uses separate parameter files for different environments:

* `dev`
* `test`
* `prod`

This allows the same Bicep infrastructure code to be reused with different configuration values.

---

## 🎯 Objectives

The main objectives of this project are to:

* Deploy Azure Bastion using Infrastructure as Code.
* Create an Azure Virtual Network and subnets using Bicep.
* Deploy a virtual machine that can be accessed through Azure Bastion.
* Organize the infrastructure using reusable Bicep modules.
* Separate infrastructure code from environment-specific configuration.
* Use parameter files for `dev`, `test`, and `prod` environments.
* Validate Bicep templates before deployment.
* Preview infrastructure changes using Azure `what-if`.
* Deploy the infrastructure using Azure CLI.
* Store and version-control the Infrastructure as Code project using GitHub.
* Document the architecture and deployment process.

---

# 🏗️ Architecture

The solution consists of an Azure Virtual Network containing the required subnets, an Azure Bastion host, and a virtual machine.

The general architecture is:

```text
                         Internet
                            │
                            │
                            ▼
                   ┌─────────────────┐
                   │  Azure Bastion  │
                   │                 │
                   │ Secure SSH/RDP  │
                   │ connectivity    │
                   └────────┬────────┘
                            │
                            │
                            ▼
              ┌───────────────────────────┐
              │        Azure VNet         │
              │                           │
              │                           │
              │ ┌───────────────────────┐ │
              │ │ AzureBastionSubnet    │ │
              │ │                       │ │
              │ │ Azure Bastion         │ │
              │ └───────────────────────┘ │
              │                           │
              │ ┌───────────────────────┐ │
              │ │ VM Subnet             │ │
              │ │                       │ │
              │ │   ┌───────────────┐   │ │
              │ │   │ Azure VM      │   │ │
              │ │   │ Private IP    │   │ │
              │ │   └───────────────┘   │ │
              │ └───────────────────────┘ │
              │                           │
              └───────────────────────────┘
```

> The `architecture` folder contains the architecture documentation and diagrams for this project.

---

# 🔐 Why Azure Bastion?

Azure Bastion provides secure management connectivity to Azure virtual machines through the Azure portal or supported client tools.

The virtual machine does not need to have a public IP address for Bastion-based management access.

This helps reduce direct Internet exposure of management protocols such as:

* SSH — TCP 22
* RDP — TCP 3389

Instead of exposing the VM directly to the Internet, the management path is:

```text
Administrator
      │
      ▼
Azure Bastion
      │
      │ Private Azure network
      ▼
Azure Virtual Machine
```

---

# 📂 Repository Structure

```text
azure-bastion-lab/
│
├── architecture/
│   └── Architecture documentation and diagrams
│
├── images/
│   └── Screenshots and project images
│
├── modules/
│   ├── bastion.bicep
│   ├── vm.bicep
│   └── vnet.bicep
│
├── parameters/
│   ├── dev.parameters.json
│   ├── test.parameters.json
│   └── prod.parameters.json
│
├── .gitignore
├── main.bicep
└── README.md
```

---

# 🧩 Bicep Architecture

The project follows a modular Bicep design.

`main.bicep` is the main entry point for the deployment.

It orchestrates the three modules:

```text
                         main.bicep
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
       vnet.bicep       bastion.bicep      vm.bicep
             │                │                │
             ▼                ▼                ▼
        Azure VNet       Azure Bastion      Azure VM
        & Subnets
```

### `main.bicep`

The main template coordinates the deployment and passes the required parameters to the individual modules.

### `modules/vnet.bicep`

Responsible for creating the networking infrastructure, including:

* Virtual Network
* Application/VM subnet
* `AzureBastionSubnet`

### `modules/bastion.bicep`

Responsible for deploying Azure Bastion and its required configuration.

### `modules/vm.bicep`

Responsible for deploying the virtual machine and its supporting resources defined by the project.

---

# 🌎 Environment Configuration

The project uses the same infrastructure code for multiple environments.

Environment-specific values are stored separately in the `parameters` folder.

```text
                 main.bicep
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
 dev.parameters  test.parameters  prod.parameters
     .json           .json            .json
       │             │                │
       ▼             ▼                ▼
     DEV           TEST             PROD
```

This approach allows the infrastructure definition to remain consistent while configuration values can change depending on the target environment.

### Development

```text
parameters/dev.parameters.json
```

Used for the development environment.

### Test

```text
parameters/test.parameters.json
```

Used for the test environment.

### Production

```text
parameters/prod.parameters.json
```

Used for the production environment.

---

# ⚙️ Technologies Used

| Technology            | Purpose                     |
| --------------------- | --------------------------- |
| Microsoft Azure       | Cloud platform              |
| Azure Bastion         | Secure VM management access |
| Azure Virtual Network | Network infrastructure      |
| Azure VM              | Compute resource            |
| Bicep                 | Infrastructure as Code      |
| Azure CLI             | Deployment and management   |
| Git                   | Version control             |
| GitHub                | Source-code repository      |
| Visual Studio Code    | Development environment     |

---

# 📋 Prerequisites

Before deploying this project, make sure you have:

* An active Azure subscription
* Azure CLI
* Bicep
* Git
* Visual Studio Code
* Bicep extension for Visual Studio Code
* Appropriate permissions to create resources in the target Azure subscription

Check Azure CLI:

```powershell
az version
```

Check Bicep:

```powershell
az bicep version
```

Check Git:

```powershell
git --version
```

---

# 🔑 Authenticate with Azure

Log in to Azure:

```powershell
az login
```

Verify the current subscription:

```powershell
az account show
```

List available subscriptions:

```powershell
az account list --output table
```

If necessary, select the subscription where you want to deploy the lab:

```powershell
az account set --subscription "<SUBSCRIPTION_NAME_OR_ID>"
```

Verify the selected subscription:

```powershell
az account show --output table
```

---

# 🧪 Validate the Bicep Template

Before deploying the infrastructure, validate the Bicep code.

Build the main template:

```powershell
az bicep build --file main.bicep
```

This checks whether the Bicep file can be compiled successfully.

You should also review any warnings reported by the Bicep compiler.

---

# 🔎 Preview Changes with What-If

Before deploying resources, use Azure `what-if` to preview the changes that Azure intends to make.

For example, for the development environment:

```powershell
az deployment group what-if `
  --resource-group "<RESOURCE_GROUP_NAME>" `
  --template-file main.bicep `
  --parameters parameters/dev.parameters.json
```

The `what-if` operation can show resources that Azure expects to:

* Create
* Modify
* Delete
* Leave unchanged

Review the output before performing the actual deployment.

---

# 🚀 Deployment

## 1. Create the Resource Group

Create a resource group for the environment.

Example:

```powershell
az group create `
  --name "rg-azure-bastion-dev" `
  --location "canadacentral"
```

Verify the resource group:

```powershell
az group show `
  --name "rg-azure-bastion-dev" `
  --output table
```

---

## 2. Deploy the Development Environment

Use the development parameter file:

```powershell
az deployment group create `
  --resource-group "rg-azure-bastion-dev" `
  --template-file main.bicep `
  --parameters parameters/dev.parameters.json
```

---

## 3. Deploy the Test Environment

Create the test resource group:

```powershell
az group create `
  --name "rg-azure-bastion-test" `
  --location "canadacentral"
```

Deploy using the test parameters:

```powershell
az deployment group create `
  --resource-group "rg-azure-bastion-test" `
  --template-file main.bicep `
  --parameters parameters/test.parameters.json
```

---

## 4. Deploy the Production Environment

Create the production resource group:

```powershell
az group create `
  --name "rg-azure-bastion-prod" `
  --location "canadacentral"
```

Deploy using the production parameters:

```powershell
az deployment group create `
  --resource-group "rg-azure-bastion-prod" `
  --template-file main.bicep `
  --parameters parameters/prod.parameters.json
```

> Make sure the parameter values in the production file are appropriate for a production environment before deploying.

---

# ✅ Verify the Deployment

List resources deployed to the resource group:

```powershell
az resource list `
  --resource-group "<RESOURCE_GROUP_NAME>" `
  --output table
```

Check the deployment status:

```powershell
az deployment group list `
  --resource-group "<RESOURCE_GROUP_NAME>" `
  --output table
```

The deployment should report a successful provisioning state.

---

# 🔐 Verify Azure Bastion

List Azure Bastion resources:

```powershell
az network bastion list `
  --resource-group "<RESOURCE_GROUP_NAME>" `
  --output table
```

Verify that the Bastion resource has been successfully deployed.

You can also inspect the Virtual Network:

```powershell
az network vnet list `
  --resource-group "<RESOURCE_GROUP_NAME>" `
  --output table
```

Verify that the required `AzureBastionSubnet` exists.

---

# 🖥️ Test Virtual Machine Access

After deployment, the VM should be accessible through Azure Bastion.

The expected management path is:

```text
Administrator
      │
      ▼
Azure Bastion
      │
      ▼
Virtual Network
      │
      ▼
VM Private IP
      │
      ▼
SSH / RDP
```

The objective is to access the VM without assigning a public IP address directly to the VM.

---

# 🔒 Security Considerations

This project demonstrates several security-oriented design principles:

### Private VM Access

The VM can be accessed through Azure Bastion without requiring a public IP address on the VM.

### Reduced Management Exposure

Direct Internet exposure of SSH and RDP to the VM can be avoided.

### Infrastructure as Code

Infrastructure configuration is stored in source control and can be reviewed and reproduced.

### Environment Separation

Separate parameter files allow different configuration values for development, testing, and production.

### Secrets

Sensitive information should never be committed to GitHub.

Do not commit:

* Passwords
* Private SSH keys
* API keys
* Client secrets
* Access tokens
* Connection strings containing credentials

---

# 🔄 Development and Deployment Workflow

The workflow used in this project is:

```text
                    ┌──────────────┐
                    │   VS Code    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    Bicep     │
                    │     IaC      │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   Validate   │
                    │ build / lint │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │     Git      │
                    └──────┬───────┘
                           │
                      git push
                           │
                           ▼
                    ┌──────────────┐
                    │    GitHub    │
                    └──────────────┘

                           │
                           │ Source Control
                           │
                           ▼

                    ┌──────────────┐
                    │  Azure CLI   │
                    └──────┬───────┘
                           │
                         what-if
                           │
                           ▼
                       Deployment
                           │
                           ▼
                    ┌──────────────┐
                    │    Azure     │
                    │              │
                    │ VNet         │
                    │ Bastion      │
                    │ VM           │
                    └──────────────┘
```

---

# 📸 Project Documentation

The project documentation is organized into the following directories:

### `architecture/`

Contains architecture-related documentation and diagrams.

### `images/`

Contains screenshots and visual evidence of the deployment and validation process.

Recommended screenshots include:

1. Repository structure
2. Bicep code validation
3. `what-if` output
4. Successful Azure deployment
5. Azure Virtual Network
6. Azure Bastion
7. Virtual machine
8. Bastion VM connection

Example:

```markdown
![Azure Bastion Architecture](architecture/architecture.png)
```

---

# 🧹 Cleanup

When the lab is no longer required, delete the resource group and its resources.

For example:

```powershell
az group delete `
  --name "rg-azure-bastion-dev" `
  --yes `
  --no-wait
```

For the test environment:

```powershell
az group delete `
  --name "rg-azure-bastion-test" `
  --yes `
  --no-wait
```

For the production environment:

```powershell
az group delete `
  --name "rg-azure-bastion-prod" `
  --yes `
  --no-wait
```

⚠️ **Warning:** Resource-group deletion permanently removes the resources contained within the resource group. Verify the resource-group name before running the command.

---

# 📚 What I Learned

This project provided hands-on experience with:

* Azure networking
* Azure Virtual Networks
* Azure subnets
* Azure Bastion
* Azure Virtual Machines
* Infrastructure as Code
* Bicep
* Bicep modules
* Parameter files
* Environment-specific configuration
* Azure CLI
* Git
* GitHub
* Deployment validation
* Azure `what-if`
* Secure VM administration
* Infrastructure documentation

One of the key concepts demonstrated by this project is the separation between **infrastructure definition** and **environment-specific configuration**.

The Bicep templates define how the infrastructure is built, while the parameter files provide values appropriate for each environment.

---

# 🚧 Future Improvements

The following improvements could be added to the project in the future:

* [ ] Add Network Security Groups (NSGs)
* [ ] Add Azure Monitor
* [ ] Add Log Analytics
* [ ] Add diagnostic settings
* [ ] Add Azure Key Vault for secrets
* [ ] Improve environment-specific configuration
* [ ] Add automated Bicep validation
* [ ] Add GitHub Actions
* [ ] Implement CI/CD deployment
* [ ] Use managed identity or workload identity for Azure authentication
* [ ] Add automated security scanning
* [ ] Add cost-management considerations
* [ ] Add Azure Policy controls

---

# 👤 Author

**Cedric Paolo Yetpa**

Azure | Networking | Infrastructure as Code | Cloud | Cybersecurity

This project was created as a hands-on Azure Infrastructure as Code lab and portfolio project.

---

# 📄 License

This project is intended for educational and demonstration purposes.

Use the configuration according to your own Azure subscription, security requirements, and organizational policies.
