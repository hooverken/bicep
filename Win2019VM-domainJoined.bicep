// Deploys a Windows Server 2019 VM with Hybrid benefit enabled

// Parameters
// most have default values except for the default admin username and password

param virtualMachineName string
param virtualMachineSize string = 'Standard_D2as_v4'

param virtualNetworkName string = 'Kentoso-VNET'
param virtualNetworkResourceGroupName string = 'Kentoso-WVD-Demo-RG'

param subnetName string = 'NewMSIXSubnet'

param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmOfferName string = 'WindowsServer'
param vmOfferSku string = '2019-Datacenter'

param adminUsername string = 'ken'
@secure()
param adminPassword string

param domainToJoin string = 'kentoso.us'
param domainJoinUsernameSecretName string = 'kentosoDomainJoinUsername'
param domainJoinPasswordSecretName string = 'kentosoDomainJoinPassword'
param keyVaultName string = 'Ken-EastUS2-KV1'
param keyVaultResourceGroupName string = 'Kentoso-WVD-Demo-RG'
param ouPath string = 'OU=NewComputers,DC=kentoso,DC=us' // joindomain can't add computers to the default "Computers" container (?!?)


// reference to VNET which is defined in another RG by adding the "scope" property
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}

// and a resource object that points to a subnet of the above vnet (parent/child relationship)
resource targetSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  parent : virtualNetwork
  name: subnetName
}

// Building the VM and its components

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
            id : targetSubnet.id
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


// key vault reference for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName) 
}

// Callout to external module to do domain join (so we can read the KV reference)
module joinDomain './joindomain-module.bicep' = {
  name: '${virtualMachineName}-domainjoin'
  dependsOn: [ 
    virtualMachine
  ]
  params: {
    virtualMachineName : virtualMachineName
    domainToJoin: domainToJoin
    ouPath: ouPath
    domainJoinUsername: keyVault.getSecret(domainJoinUsernameSecretName)
    domainJoinPassword: keyVault.getSecret(domainJoinPasswordSecretName)
  }
}

output virtualMachineName string = virtualMachineName
output virtualMachineSize string = virtualMachineSize
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

