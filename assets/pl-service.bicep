param backendVmIp string = '10.3.1.4'
param vnetName string = 'vnet-plink-service'
param subnetName string = 'default'

param suffix string = 'odata-service'

var location = resourceGroup().location

var lbName = 'lb-${suffix}'
var feName = 'front-end-${suffix}'
var poolName = 'pool-${suffix}'
var probeName = 'probe-${suffix}'
var plsName = 'pl-${suffix}'


resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnetName}/${subnetName}'
}

resource pool 'Microsoft.Network/loadBalancers/backendAddressPools@2020-11-01' = {
  name: '${lbName}/${poolName}'
  properties: {
    loadBalancerBackendAddresses: [{
        name: 'backend-address-${suffix}'
        properties: {
          ipAddress: backendVmIp
          virtualNetwork: {
            id: vnet.id
          }
        }
      }
    ]
  }
}

resource lb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [{
        name: feName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
        zones: [
          '1'
          '2'
          '3'
        ]
      }
    ]
    backendAddressPools: [{
        name: poolName
      }
    ]
    probes: [{
        name: probeName
        properties: {
          port: 80
          protocol: 'Http'
          requestPath: '/'
        }
      }
    ]
    loadBalancingRules: [{
        name: 'rule-http-forward'
        properties: {
          frontendPort: 80
          backendPort: 80
          protocol: 'Tcp'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontEndIpConfigurations', lbName, feName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, poolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, probeName)
          }
        }
      }
    ]
  }
}

// resource pdnsz 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: 'contoso.com'
//   location: location
// }

// resource pls 'Microsoft.Network/privateLinkServices@2020-11-01' = {
//   name: plsName
//   location: location
//   properties: {
//   }
// }

