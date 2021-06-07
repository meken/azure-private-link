param vnetName string
param peeringName string
param vnetRemoteId string

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${vnetName}/${peeringName}'
  properties: {
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: vnetRemoteId
    }
  }
}
