// Deploys a Windows Server 2019 VM with Hybrid benefit enabled

// Parameters
param virtualMachineName string
param virtualMachineSize string

param virtualNetworkName string
param virtualNetworkResourceGroupName string
param subnetName string

param adminUsername string
param adminPassword string

// If you want the VM to be domain joined and/or to be added to a host pool,
// set the booleans to true and provide valid values for the two parameters below
param joinDomain bool = false
param domainName string = 'NODOMAIN'
param ouPath string = 'NOPATH'
param domainJoinUsername string = 'NOUSER'
@secure()
param domainJoinPassword string = ''

// If you want the VM to be added to a host pool, set the bool to true and provide values
param joinHostPool bool = false

param wvdHostPoolName string = 'defaultHostPoolName'
@secure()
param wvdHostPoolRegistrationToken string = 'NOTOKEN'

// Variables
var subnetId = '${subscription().id}/resourceGroups/${virtualNetworkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'
var vmImagePublisher = 'MicrosoftWindowsDesktop'
var vmImageOffer = 'Windows-10'
var vmImageSku = '20H2-EVD'
var wvd_sessionHostDSCModuleZipUri = ''


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

// define the NIC for the VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: '${virtualMachineName}-NIC'
  location: resourceGroup().location
  properties: {
    // enableAcceleratedNetworking: true
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
    licenseType: 'Windows_Server'
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
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


// AD Domain Join (if requested)
resource joinVmToDomain 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if (joinDomain) {
  name: '${virtualMachine.name}/joindomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion : '1.3'
    autoUpgradeMinorVersion : true
    settings: {
      name: domainName
      User : '${domainJoinUsername}@${domainName}'
      OUPath: ouPath
      restart: true 
      Options: '3'
    }
    protectedSettings: {
      password: domainJoinPassword
    }
  }
}

//WVD Host Pool Join DSC (if desired)
// resource installWvdAgent 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = if(joinHostPool) {
//   name: '${virtualMachine.name}/Microsoft.PowerShell.DSC'
//   location: resourceGroup().location
//   properties:{
//     publisher: 'Microsoft.Powershell'
//     type: 'DSC'
//     typeHandlerVersion: '2.80'
//     autoUpgradeMinorVersion: true
//   }

//   settings: {
//     Configuration: {
//       url: wvd_sessionHostDSCModuleZipUri
//       script: dscScriptName
//       function: dscConfigurationName
//     }
//     configurationArguments: {
//       hostPoolName: wvdHostPoolName
//       registrationInfoToken: wvdHostPoolRegistrationToken
//       wvdDscConfigZipUrl": "[parameters('wvd_dscConfigZipUrl')]
//       deploymentFunction": "[parameters('wvd_deploymentFunction')]
//       deploymentType": "[parameters('wvd_deploymentType')]
//     }
//   }
// }



output virtualMachineName string = virtualMachineName
output virtualMachineSize string = virtualMachineSize
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
