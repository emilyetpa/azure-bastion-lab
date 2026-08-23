param location string

param publicIpId string

param AzureBastionSubnetId string

param environment string

resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: 'bas-${environment}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: AzureBastionSubnetId
          }
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]
  }
}

output bastionHostId string = bastion.id
