// secureDataAnalysisEnclave.bicep
// Secure Enclave for Research

// Resources:
// WVD environment for jump boxes
// Linux machines for analysis
// Linux machine for data movement approvals?
// storage account to hold the data to be worked on (NFS jounted by linux machines?)
// 

param analyticsVmName string = 'analyticsVM1'
param analyticsVmSize string = 'Standard_B2ms'

// storage account for secure data.  blob container will have private endpoint on analytics host vnet.
resource secureDataStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: secureDataStorageAccountName
  location: resourceGroup().location
  sku: secureDataStorageAccountSku
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    isNfsV3Enabled: true
  }
}

resource jumpBoxAvdHostPool 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  name: jumpBoxHostPoolName
  location: resourceGroup().location
  properties: {
    loadBalancerType: 'BreadthFirst'
    hostPoolType: 'Pooled'
    startVMOnConnect: true
    validationEnvironment: true
  }

}

resource jumpBoxAvdApplicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-04-01-preview' = {
  name: jumpBoxAveApplicationGroupName
  location: resourceGroup().location
}


resource analyticsNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' {
  name: analyticsVmName
}


resource analyticsHostVnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: analyticsHostVnetName
  location: resourceGroup().location
  properties: {
    addressSpace: '10.10.0.0/16'
    subnets: [
      {
        name: 'analysisHostSubnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
    ]
  }
}

resource jumpBoxSessionHostsAvailabilitySet 'Microsoft.Compute/availabilitySets@2021-03-01' = {
  name: jumpBoxHostAvailabilitySetName
  location: resourceGroup().location
  properties: {
    virtualMachines: [
      analyticsVm.id
    ]
  }
}

resource analyticsVmNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${analyticsVmName}-NIC1'
  location: resourceGroup().location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        properties: {
          subnet: '${analyticsVmSubnet}'
        }
      }
    ]
  }
}

resource analyticsVm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: analyticsVmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: analyticsVmSize
    }
    osProfile: {
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: analyticsHostVmSshPublicKey
        }
      }
    }
    storageProfile: {
      imageReference: {
        vmImagePublisher: 'Canonical'
        vmOfferName : 'UbuntiServer'
        vmOfferSku : '18.04-LTS'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: analyticsVmNic.id
        }
      ]
    }
  }
}
