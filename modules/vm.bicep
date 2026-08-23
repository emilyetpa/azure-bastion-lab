param location string

param environment string

param subnetId string

param vmSize string

param adminUsername string = 'azureuser'

@description('SSH public key used to access the VM.')
param adminSshPublicKey string

var vmName = 'vm-${environment}'
var nicName = '${vmName}-nic'

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
	name: nicName
	location: location
	properties: {
		ipConfigurations: [
			{
				name: 'ipconfig'
				properties: {
					privateIPAllocationMethod: 'Dynamic'
					subnet: {
						id: subnetId
					}
				}
			}
		]
	}
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
	name: vmName
	location: location
	properties: {
		hardwareProfile: {
			vmSize: vmSize
		}
		storageProfile: {
			imageReference: {
				publisher: 'Canonical'
				offer: 'ubuntu-24_04-lts'
				sku: 'server'
				version: 'latest'
			}
			osDisk: {
				createOption: 'FromImage'
				managedDisk: {
					storageAccountType: 'Premium_LRS'
				}
			}
		}
		osProfile: {
			computerName: vmName
			adminUsername: adminUsername
			linuxConfiguration: {
				disablePasswordAuthentication: true
				ssh: {
					publicKeys: [
						{
							path: '/home/${adminUsername}/.ssh/authorized_keys'
							keyData: adminSshPublicKey
						}
					]
				}
			}
		}
		networkProfile: {
			networkInterfaces: [
				{
					id: networkInterface.id
					properties: {
						primary: true
					}
				}
			]
		}
	}
}

output vmId string = virtualMachine.id
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
