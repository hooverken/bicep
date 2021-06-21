// Azure FW in front of a LB and app gw for split-path traffic flows

param loadBalancerName string
param loadBalancerInternalVnetName string
param loadBalancerSubnetName string
param loadBalancerPublicIpAddressName string

param loadBalancerBackEndPoolVnetName string

param backEndIpAddresses array = [
  '1.2.3.4'
  '5.6.7.8'
]

@allowed([
  'Standard'
  'Basic'
])
param loadBalancerSku string = 'Standard'
param loadBalancerIsGloballyRedundant bool = false


resource loadBalancerInternalVnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: loadBalancerInternalVnetName
}

resource loadBalancerBackEndVnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: loadBalancerBackEndPoolVnetName
}

resource loadBalancerPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-11-01' existing = {
  name: loadBalancerPublicIpAddressName
}


// Azure Firewall


// Standard load balancer
resource standardLoadBalancer 'Microsoft.Network/loadBalancers@2020-07-01' = {
  name: loadBalancerName
  location: resourceGroup().location
  sku: {
    name: loadBalancerSku
    tier: loadBalancerIsGloballyRedundant ? 'Global' : 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '1.2.3.4'
          privateIPAddressVersion: 'IPv4' 
          subnet: {
            id: '${loadBalancerInternalVnet.id}/subnets/${loadBalancerSubnetName}'
          }
          publicIPAddress: {
            id: loadBalancerPublicIpAddress.id
          }
        }
        name: '${loadBalancerName}-frontEntIpAddress'
      }
    ]
    backendAddressPools: [
      {
        name: '${loadBalancerName}-backEndAddressPool'
      }
    ]
    loadBalancingRules: [
      {
        id: '${loadBalancerName}-LoadBalancingRule1'
        properties: {
          frontendIPConfiguration: {
            id: 'string'
          }
          backendAddressPool: {
            id: 'string'
          }
          probe: {
            id: 'string'
          }
          protocol: 'string'
          loadDistribution: 'string'
          frontendPort: int
          backendPort: int
          idleTimeoutInMinutes: int
          enableFloatingIP: bool
          enableTcpReset: bool
          disableOutboundSnat: bool
        }
        name: 'string'
      }
    ]
    probes: [
      {
        id: 'string'
        properties: {
          protocol: 'string'
          port: int
          intervalInSeconds: int
          numberOfProbes: int
          requestPath: 'string'
        }
        name: 'string'
      }
    ]
    inboundNatRules: [
      {
        id: 'string'
        properties: {
          frontendIPConfiguration: {
            id: 'string'
          }
          protocol: 'string'
          frontendPort: int
          backendPort: int
          idleTimeoutInMinutes: int
          enableFloatingIP: bool
          enableTcpReset: bool
        }
        name: 'string'
      }
    ]
    inboundNatPools: [
      {
        id: 'string'
        properties: {
          frontendIPConfiguration: {
            id: 'string'
          }
          protocol: 'string'
          frontendPortRangeStart: int
          frontendPortRangeEnd: int
          backendPort: int
          idleTimeoutInMinutes: int
          enableFloatingIP: bool
          enableTcpReset: bool
        }
        name: 'string'
      }
    ]
    outboundRules: [
      {
        id: 'string'
        properties: {
          allocatedOutboundPorts: int
          frontendIPConfigurations: [
            {
              id: 'string'
            }
          ]
          backendAddressPool: {
            id: 'string'
          }
          protocol: 'string'
          enableTcpReset: bool
          idleTimeoutInMinutes: int
        }
        name: 'string'
      }
    ]
  }
  resources: []
}
// Application gateway
