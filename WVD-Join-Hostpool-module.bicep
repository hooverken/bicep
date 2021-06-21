// This module runs the extension to add a VM to the specified host pool.

param virtualMachineName string
param hostPoolName string
param registrationToken string

resource installWvdAgent 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {

  name: '${virtualMachineName}/HostPoolAdd'
  location: resourceGroup().location
  properties:{
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft/Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1-25-2021.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolName
        registrationInfoToken: registrationToken
        aadJoin: false
      }
    }
  }
}
