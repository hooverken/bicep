// Just returns info about the resource of the specified name and type.
// Doesn't actually deploy any resources.
resource vnetInfo 'Microsoft.Network/virtualNetworks@2020-06-01' existing = { 
  name : 'kentoso-VNET' 
}

output VnetName string = vnetInfo.name