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
param adminPassword string {
  secure: true
}

param domainNetBIOSName string
param ouPath string = 'CN=Computers,DC=kentoso,DC=us'  // default value, can be overridden
param domainJoinUsername string
param domainJoinPassword string {
  secure: true
}

// Variables
var subnetId = '${subscription().id}/resourceGroups/${virtualNetworkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'

// Building the VM and its components

// A reference to the target vNet/subnet so we can use it easily later
// resource vnetInfo 'Microsoft.Network/virtualNetworks@2020-06-01' existing = { 
//  name : virtualNetworkName 
// }

// The Availability set for the VM.  Need to figure out how to create it if it doesn't exist.
// resource availabilitySet 'Microsoft.Compute/availabilitySets@2020-06-01' existing = {
//   name: availabilitySetName
// }



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
  }
}

// NSG for the NIC
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01'= {
  name: '${virtualMachineName}-NSG'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'default-allow-RDP'
        properties: {
          priority: 1000
          direction:'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange:'*'
          protocol: 'Tcp'
          destinationAddressPrefix:'*'
          destinationPortRange: '3389'
          access:'Allow'
        }
      }
      {
        name: 'default-allow-winrm-5985'
        properties: {
          priority: 1100
          direction:'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange:'*'
          protocol: 'Tcp'
          destinationAddressPrefix:'*'
          destinationPortRange: '5985'
          access:'Allow'
        }
      }
    ]
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
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        timeZone: 'Eastern Standard Time'
        winRM: {
          listeners: [
            {
              protocol:'Http'
            }
          ]
        }
      }
    }
    licenseType: 'Windows_Server'  // for Azure hybrid benefit
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

module joinDomain './joindomain-module.bicep' = {
  name: '${virtualMachineName}-domainjoin'
  params: {
    domainNetBIOSName: domainNetBIOSName
    ouPath: ouPath
    username: domainJoinUsername
    password: domainJoinPassword
  }
}

output virtualMachineName string = virtualMachineName
output virtualMachineSize string = virtualMachineSize
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

