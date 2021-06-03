param suffix string = 'odata-service'
param userName string = 'odata'
@secure()
param password string = concat('P', uniqueString(resourceGroup().id), 'x!')

var location = resourceGroup().location

// names of resources
var vnetName = 'vnet-on-prem'
var subnetName = 'subnet-${suffix}'


resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-on-prem'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.3.1.0/24'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: '${vnet.name}/${subnetName}'
}


module odataServer 'reverse-proxy.bicep' = {
  name: 'vm-odata'
  params: {
    userName: userName
    password: password
    proxyTarget: '"https://services.odata.org/V3/Northwind/"'
    subnetId: subnet.id
    suffix: suffix
  }
}

output vnetId string = vnet.id // needed for peering
output vmIp string = odataServer.outputs.vmIp
