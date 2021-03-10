// Deploys a Windows Server 2019 VM with Hybrid benefit enabled

// Parameters
param virtualMachineName string
param virtualMachineSize string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param subnetName string

param vmImagePublisher string
param vmOfferName string
param vmOfferSku string

param adminUsername string
param adminSSHPublicKey string

// Variables
var subnetId = '${subscription().id}/resourceGroups/${virtualNetworkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'

// Building the VM and its components

// The Availability set for the VM.  Need to figure out how to create it if it doesn't exist.
// resource availabilitySet 'Microsoft.Compute/availabilitySets@2020-06-01' existing = {
//   name: availabilitySetName
// }

// NSG for the NIC
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01'= {
  name: '${virtualMachineName}-NSG'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'default-allow-SSH'
        properties: {
          priority: 1000
          direction:'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange:'*'
          protocol: 'Tcp'
          destinationAddressPrefix:'*'
          destinationPortRange: '22'
          access:'Allow'
        }
      }
    ]
  }
}

// define the NIC for the VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: '${virtualMachineName}-NIC'
  location: resourceGroup().location
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id : subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}


// Build the VM itself
resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: resourceGroup().location
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminSSHPublicKey
      linuxConfiguration: {
        provisionVMAgent: true
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/ken/.ssh/authorized_keys'
              keyData: adminSSHPublicKey
            }
          ]
        }
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmOfferName
        sku: vmOfferSku
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}-OSdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}


output virtualMachineName string = virtualMachineName
output virtualMachineSize string = virtualMachineSize
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

