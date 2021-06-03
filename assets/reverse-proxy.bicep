param suffix string
param subnetId string
param proxyTarget string
param userName string
@secure()
param password string

param lbBackendPools array  = []

var location = resourceGroup().location

var vmName = 'vm-${suffix}'
var nicName = 'nic-${suffix}'
var ipConfigName = 'ipconfig-${suffix}'
var nsgName = 'nsg-${suffix}'

var vmType = 'Standard_D2s_v3'


resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-http'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '80'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: ipConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          loadBalancerBackendAddressPools: lbBackendPools
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmType
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: userName
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        { 
          id: nic.id 
        }
      ]
    }
  }
}

resource nginx 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vm.name}/nginx'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/meken/azure-private-link/main/assets/install-nginx.sh'
      ]
      commandToExecute: 'sh install-nginx.sh "${proxyTarget}"'
    }
  }
}

output vmIp string = reference(nic.id, '2020-11-01').ipConfigurations[0].properties.privateIPAddress
