param location string

param subnets array = [
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '172.20.11.0/26'
  }
  {
    name: 'app'
    addressPrefix: '172.20.10.0/24'
  }
  {
    name: 'database'
    addressPrefix: '172.20.12.0/24'
  }
]

param environment string

var vnetName = 'vnet-${environment}'

resource vnet  'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.20.0.0/16'
      ]
    }

    subnets: [
      {
        name: subnets[1].name
        properties: {
          addressPrefix: subnets[1].addressPrefix
        }
      }
       
      {
        name: subnets[0].name
        properties: {
          addressPrefix: subnets[0].addressPrefix
        }
      }
      {
        name: subnets[2].name
        properties:{
          addressPrefix: subnets[2].addressPrefix        
        }
      }
        ]
  }

}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-bastion-${environment}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output vnetId string = vnet.id
output publicIpId string = publicIp.id
output appSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'app'
)
output AzureBastionSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'AzureBastionSubnet'
)
