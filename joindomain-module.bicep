// This is a Bicep module to invoke the JsonADDomainExtension, which attaches a Windows VM to ADDS.

param virtualMachineName string   // Name of VM that we are joining
param domainToJoin string         // Full (FQDN-like) name of ADDS domain to join (ad.contoso.com)
param ouPath string               // Full DN of the OU to create the new computer object in (don't use default Computers OU)

@secure()
param domainJoinUsername string   // username to use for domain join in UPN format user@ad.contoso.com

@secure()
param domainJoinPassword string   // password for the above user


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

