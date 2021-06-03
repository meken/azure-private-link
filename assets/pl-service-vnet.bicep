param suffix string = 'odata-service'

var location = resourceGroup().location

var vnetName = 'vnet-plink-service'
var subnetName = 'subnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '172.1.1.0/24'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${subnetName}'
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output subnetId string = subnet.id
