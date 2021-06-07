param suffix string = 'odata-service'

param vmOnPremIp string
param vnetOnPremId string
param vnetOnPremName string
param rgOnPremName string

param userName string = 'proxy'
@secure()
param password string = newGuid()

var location = resourceGroup().location

var lbName = 'lb-${suffix}'
var feName = 'front-end-${suffix}'
var poolName = 'pool-${suffix}'
var probeName = 'probe-${suffix}'

var plsName = 'pl-${suffix}'

var domainName = 'contoso.com'
var proxyDNS = 'proxy-${suffix}'
var sourceDNS = 'on-prem-${suffix}'

var vnetName = 'vnet-plink-service'
var subnetName = 'subnet-plink-${suffix}'
var vnetCIDR = '192.168.0.0/16'
var subnetCIDR = '192.168.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCIDR
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetCIDR
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${subnetName}'
}

module peering1 'vnet-peer.bicep' = {
  name: 'plink-to-on-prem'
  params: {
    peeringName: 'peer-on-prem-to-plink'
    vnetName: vnet.name
    vnetRemoteId: vnetOnPremId
  }
}

module peering2 'vnet-peer.bicep' = {
  name: 'on-prem-to-plink'
  scope: resourceGroup(rgOnPremName)
  params: {
    peeringName: 'peer-on-prem-to-plink'
    vnetName: vnetOnPremName
    vnetRemoteId: vnet.id
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
            id: subnet.id // could be a different subnet as well
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
          intervalInSeconds: 60
        }
      }
    ]
    loadBalancingRules: [{
        name: 'rule-http-forward'
        properties: {
          frontendPort: 80
          backendPort: 80
          protocol: 'Tcp'
          disableOutboundSnat: true
          enableTcpReset: true
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
      id: vnet.id
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
        ipv4Address: vmOnPremIp
      }
    ]
  }
}

module proxyServer 'reverse-proxy.bicep' = {
  name: 'vm-${proxyDNS}'
  params: {
    userName: userName
    password: password
    proxyTarget:  'http://${sourceDNS}.${domainName}/'
    subnetId: subnet.id
    suffix: proxyDNS
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
            id: subnet.id
          }
        }
      }
    ]
  }
}

output lbName string = lbName
output poolName string = poolName
output ipConfigId string = proxyServer.outputs.vmIpConfigId
output plsName string = pls.name
output plsId string = pls.id
output plsFqdns string = '${sourceDNS}.${domainName}'
