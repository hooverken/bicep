param domainNetBIOSName string
param ouPath string
param username string
param password string {
  secure: true
} 

var domainJoinOptions = 3  // required but not sure what it means :-)

resource joinDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${domainNetBIOSName}-join'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion : '1.3'
    autoUpgradeMinorVersion : true
    settings: {
      name: domainNetBIOSName
      OUPath: ouPath
      User : '${domainNetBIOSName}\\${username}'
      restart: true 
      Options: domainJoinOptions
    }
    protectedSettings: {
      password: password
    }
  }
}
