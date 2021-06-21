// This is a Bicep module to run the JsonADDomainExtension, which attaches a Windows VM to ADDS.

param virtualMachineName string
param domainToJoin string
param ouPath string

@secure()
param domainJoinUsername string

@secure()
param domainJoinPassword string // passed in via key vault reference


var domainJoinOptions = 3  // required

resource joinDomain 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachineName}/joindomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion : '1.3'
    autoUpgradeMinorVersion : true
    settings: {
      name: domainToJoin
      User : domainJoinUsername
      OUPath: ouPath
      restart: true 
      Options: domainJoinOptions
    }
    protectedSettings: {
      password: domainJoinPassword
    }
  }
}

