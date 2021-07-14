// this file deploys a UPitt-style "analysis pod"

// Ingredients:

// VNET
// Azure Storage Account with a private endpoint
// Linux VM(s)
// NSG for the VNET

resource analysisVmVnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'analyticsVnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'analyticsVmSubnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: sshOnlyNSG.id
          }
        }
      }
    ]
  }
}

resource sshOnlyNSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'analyticsVmNSG'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'allowSshInbound'  // allow ssh inbound to this vnet from anywhere
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.10.0.0/16'
          destinationPortRange: '22'
          protocol: 'Tcp'
          priority: 1111
        }
      }
    ]
  }
}

resource analyticsStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'kentososdsaccount'
  location: resourceGroup().location
  kind: 'BlobStorage'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource analyticsStorageAccountPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'analyticsStorageAccountPrivateEndpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: analysisVmVnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'privateLinkServiceConnection1'
        properties: {
          privateLinkServiceId: analyticsStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

var arr = [
  '1'
  '2'
  '3'
]

resource analyticsVmNic 'Microsoft.Network/networkInterfaces@2020-07-01' = [ for i in arr: {
  name: 'analyticsVmNic-${i}'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: analysisVmVnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: sshOnlyNSG.id
    }
  }
}]



resource analyticsUbuntuVm 'Microsoft.Compute/virtualMachines@2020-06-01' = [ for i in arr: {
  name: 'analyticsVm-${i}'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        createOption: 'FromImage'
        name: 'analyticsVm-${i}-OSDisk'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: 'analyticsVm-${i}'
      adminUsername: 'budweiserfrog'
      adminPassword: 'ribbbbbbbbbbit'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/budweiserfrog/.ssh/authorized_keys'
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDsqIjaliFVPOa1S/9zWUQNcKEcW7cajTcbg2z/D68OypK15lu7NL4RxD4j3qUXePEmGPeOt2M4Sg2USMR9gd2G8LTmY1yNZ86lG4DLPUle0LyChZOSV0jGw0mbAy3yc16zS2yWiR5g8MlkgMJ1NxDGNF9MNVurOfZSHJICzTZ/t/NKSxItObgZGIsnC3pIvNw0bDnsfLcTikLbuNC2onR+4yAE5zBLZzYsKMzNiftF+jChXl9uFu0miWcExAb2DQELGWru+LxjdHaS2T0Z7ax6rbMR2qsmO3zGiZta3WBzxIbW4a3+NvmSOmj181mNpcTAhd8N7cy6QE88fDUmZM5x northamerica\\kenhoover@DESKTOP-BBU56DD'
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: '${resourceGroup().id}/providers/Microsoft.Network/networkInterfaces/analyticsVmNic-${i}'
        }
      ]
    }
  }
}]
