param location string = resourceGroup().location

param vmSize string

@description('SSH public key used to access the VM.')
param adminSshPublicKey string

@allowed([
  'dev'
  'prod'
  'test'
])
param environment string

module vnetModule 'modules/vnet.bicep' = {
  name: 'vnetModule'
  params: {
    location: location
    environment: environment
  }
}

module bastionModule 'modules/bastion.bicep' = {
  name: 'bastionModule'
  params: {
    location: location
    publicIpId: vnetModule.outputs.publicIpId
    AzureBastionSubnetId: vnetModule.outputs.AzureBastionSubnetId
    environment: environment
  }
}

module vmModule 'modules/vm.bicep' = {
  name: 'vmModule'
  params: {
    location: location
    environment: environment
    subnetId: vnetModule.outputs.appSubnetId
    adminSshPublicKey: adminSshPublicKey
    vmSize: vmSize
  }
}
