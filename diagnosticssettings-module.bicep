// This module applies diagnotics settings to a VM
param virtualMachineName string
param storageAccountName string
@secure
param storageAccountkey string

param xmlCfg string

resource diagnosticsStorageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' existing = {
  name: storageAccountName
}

resource diagnosticsSettings 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachineName}-diagsettings'
  properties:{
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'IaaSDiagnostics'
    typeHandlerVersion: '1.5'
    settings: {
      StorageAccount: storageAccountName
      xmlCfg: xmlConfiguration
    }
    protectedSettings: {
      storageAccountName: diagnosticsStorageAccount.name
      storageAccountKey: storageAccountkey
      storageAccountEndpoint: diagnosticsStorageAccount.properties.

    }
  }
  
}

        {
            "type": "Microsoft.Compute/virtualMachines/extensions",
            "apiVersion": "2020-12-01",
            "name": "[concat(parameters('virtualMachines_ADVM1_name'), '/Microsoft.Insights.VMDiagnosticsSettings')]",
            "location": "eastus2",
            "dependsOn": [
                "[resourceId('Microsoft.Compute/virtualMachines', parameters('virtualMachines_ADVM1_name'))]"
            ],
            "properties": {
                "autoUpgradeMinorVersion": true,
                "publisher": "Microsoft.Azure.Diagnostics",
                "type": "IaaSDiagnostics",
                "typeHandlerVersion": "1.5",
                "settings": {
                    "StorageAccount": "kentosodiagstor",
                    "xmlCfg": "[parameters('extensions_Microsoft_Insights_VMDiagnosticsSettings_xmlCfg')]"
                },
                "protectedSettings": {
                    "storageAccountName": "[parameters('extensions_Microsoft_Insights_VMDiagnosticsSettings_storageAccountName')]",
                    "storageAccountKey": "[parameters('extensions_Microsoft_Insights_VMDiagnosticsSettings_storageAccountKey')]",
                    "storageAccountEndPoint": "[parameters('extensions_Microsoft_Insights_VMDiagnosticsSettings_storageAccountEndPoint')]"
                }
            }
        }
    ]
}
