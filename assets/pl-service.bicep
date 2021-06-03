param backendVmIp string
param vnetOnPremId string
param vnetPrivateLinkId string
param subnetPrivateLinkId string
param userName string = 'proxy'
@secure()
param password string = concat('P', uniqueString(resourceGroup().id), 'x!')
param suffix string = 'odata-service'

var location = resourceGroup().location

var lbName = 'lb-${suffix}'
var feName = 'front-end-${suffix}'
var poolName = 'pool-${suffix}'
var probeName = 'probe-${suffix}'

var plsName = 'pl-${suffix}'

var domainName = 'contoso.com'
var proxyDNS = 'proxy-${suffix}'
var sourceDNS = 'on-prem-${suffix}'


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
            id: subnetPrivateLinkId // could be a different subnet as well
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

resource pdnsz 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: domainName
  location: 'global'
}

resource pdnszVnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${pdnsz.name}/link-vnet-plink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetPrivateLinkId
    }
  }
}

resource pdnszVnetOnPrem 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${pdnsz.name}/link-vnet-on-prem'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetOnPremId
    }
  }
}

resource pdnszRecordProxy 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${pdnsz.name}/${proxyDNS}'
  properties: {
    ttl: 3600
    aRecords: [{
        ipv4Address: lb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
  }
}

resource pdnszRecordSource 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${pdnsz.name}/${sourceDNS}'
  properties: {
    ttl: 3600
    aRecords: [{
        ipv4Address: backendVmIp
      }
    ]
  }
}

module proxyServer 'reverse-proxy.bicep' = {
  name: 'vm-proxy-${suffix}'
  params: {
    userName: userName
    password: password
    proxyTarget: '${proxyDNS}.${domainName}'
    subnetId: subnetPrivateLinkId
    suffix: suffix
  }
}

resource pls 'Microsoft.Network/privateLinkServices@2020-11-01' = {
  name: plsName
  location: location
  properties: {
    visibility: {
      subscriptions: [
        subscription().subscriptionId
      ]
    }
    loadBalancerFrontendIpConfigurations: [{
        id: lb.properties.frontendIPConfigurations[0].id
      }
    ]
    ipConfigurations: [{
        name: 'default-${suffix}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetPrivateLinkId
          }
        }
      }
    ]
  }
}

