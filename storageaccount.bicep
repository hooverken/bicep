// You can include comments!
param storageAccountNameParam string = 'kentososg1a'

var storageAccountSkuVar = 'Standard_LRS'

resource storageAccount1 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountNameParam // must be globally unique
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSkuVar
  }
}

output storageId string = storageAccount1.id
