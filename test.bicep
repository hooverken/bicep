param loadBalancerInternalVnetName string = 'Kentoso-VNET'
param loadBalancerSubnetName string = 'DesktopHostSubnet'

resource loadBalancerInternalVnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: loadBalancerInternalVnetName
}

resource loadBalancerSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' existing = {
  id: '${loadBalancerInternalVnet.id}/subnets/${loadBalancerSubnetName}'
}


output vnetId string = loadBalancerInternalVnet.id
output subnetId string = loadBalancerSubnet.id
