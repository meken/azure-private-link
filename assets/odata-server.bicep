param baseName string = 'odata'
param userName string = 'odata'
@secure()
param password string = concat('P', uniqueString(resourceGroup().id), 'x!')

var location = resourceGroup().location
var resourceSuffix = substring(concat(baseName, uniqueString(resourceGroup().id)), 0, 8)

var subnetName = 'subnet-odata-service'
var vmType = 'Standard_D2s_v3'

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-${resourceSuffix}'
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

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsg-${resourceSuffix}'
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
  name: 'nic-${resourceSuffix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-${resourceSuffix}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-${resourceSuffix}'
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
      computerName: 'vm-odata-server'
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
      commandToExecute: 'apt update && apt install -y nginx'
    }
  }
}
