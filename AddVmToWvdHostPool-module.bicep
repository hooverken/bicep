// This doesn't work... yet

param artifactsLocation string
param hostPoolName string
param hostPoolRegistrationToken string
param aadJoin string
param hostNamePrefix string
param location string

resource joinToHostPool 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  
  name: '${hostNamePrefix}/Microsoft.PowerShell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolName
        registrationInfoToken: hostPoolRegistrationToken
        aadJoin: aadJoin
      }
    }
  }
}
