param onPremVnetId string 

var location = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-plink-service'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.4.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.4.1.0/24'
        }
      }
    ]
  }
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${vnet.name}/peer-plink-to-on-prem'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    remoteVirtualNetwork: {
        id: onPremVnetId
    }    
  }
}

