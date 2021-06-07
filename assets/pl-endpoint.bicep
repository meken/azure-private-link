param suffix string = 'odata-service'
param privateLinkServiceId string
param privateLinkServiceFqdns string


var location = resourceGroup().location


resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'adf-${suffix}'
  location: location
}

resource vnetManaged 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${adf.name}/default'
  properties: {
    preventDataExfiltration: false
  }
}

resource irAuto 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${adf.name}/AutoResolveIntegrationRuntime'
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 0
        }
      }
    }
    managedVirtualNetwork: {
      type: 'ManagedVirtualNetworkReference'
      referenceName: last(split(vnetManaged.name, '/'))
    }
  }
}

resource privateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  name: '${adf.name}/${last(split(vnetManaged.name, '/'))}/PrivateLinkServiceOData'
  properties: {
    privateLinkResourceId: privateLinkServiceId
    fqdns: [
      privateLinkServiceFqdns
    ]
  }
}

resource lsOData 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${adf.name}/ODataNorthwind'
  properties: {
    type: 'OData'
    typeProperties: {
      url: 'http://${privateLinkServiceFqdns}'
      authenticationType: 'Anonymous'
    }
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: last(split(irAuto.name, '/'))
    }
  }
}

resource dsOData 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${adf.name}/ODataCustomers'
  properties: {
    type: 'ODataResource'
    typeProperties: {
      path: 'Customers'
    }
    linkedServiceName: {
      referenceName: last(split(lsOData.name, '/'))
      type: 'LinkedServiceReference'
    }
  }
}
