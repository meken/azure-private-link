param onPremVnetId string 

var location = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-plink-service'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '172.1.0.0/24'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

