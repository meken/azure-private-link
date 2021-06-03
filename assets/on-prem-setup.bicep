param suffix string = 'odata-service'

param userName string = 'odata'
@secure()
param password string = newGuid()

var location = resourceGroup().location

var vnetName = 'vnet-on-prem'
var subnetName = 'subnet-on-prem-${suffix}'


resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${subnetName}'
}

module odataServer 'reverse-proxy.bicep' = {
  name: 'vm-${suffix}'
  params: {
    userName: userName
    password: password
    proxyTarget: 'https://services.odata.org/V3/Northwind/'
    subnetId: subnet.id
    suffix: suffix
  }
}

output vnetName string = vnet.name // needed for peering
output vnetId string = vnet.id // needed for peering
output vmIp string = odataServer.outputs.vmIp
