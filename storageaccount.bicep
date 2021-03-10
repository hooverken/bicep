param locationParam string = 'eastus2'

@minLength(3)
@maxLength(24)
param storageAccountNameParam string = 'kentososg1a'

var storageAccountSkuVar = 'Standard_LRS'

resource storageAccount1 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountNameParam // must be globally unique
  location: resourceGroup().location
  kind: 'Storage'
  sku: {
    name: storageAccountSkuVar
  }
}

output storageId string = storageAccount1.id