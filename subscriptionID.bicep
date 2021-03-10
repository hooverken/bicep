// Just returns the subscription ID.  Doesn't actually deploy any resources.
resource vnetInfo 'Microsoft.Network/virtualNetworks@2020-06-01' existing = { 
  name : 'kentoso-VNET' 
}

output Id string = subscription().id
