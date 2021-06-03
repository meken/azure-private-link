# Using Private Links to access on premises sources

The purpose of this repository is to illustrate how to set up a [Private Link](TODO) connection to access resources on private and/or on-premises networks. For the sake of the example we'll create an isolated virtual network to represent the private network. The end result will look like this:

![Final Architecture](./images/plinks-architecture.svg)

> TODO explain the picture.

## Mocking the on-premises environment

In order to mimic an on-prem data source, we'll create a new resource group with a new Virtual Network and put the VM that's going to host the OData service on that network. All resources will be created in the same location as the resource group, so pick one that's the closest to you.

```shell
LOCATION=westeurope
RG_ON_PREM=rg-on-prem
az group create -n $RG_ON_PREM -l $LOCATION
```

Once the resource group is ready, we can deploy the sample OData service. The command below will create a new VM (DS2_v3) with a reverse proxy to `https://services.odata.org/V3/Northwind/`, which is an online demo OData service. For the purposes of this example, just assume that the VM **is** the data source. And please note it can only be accessed through the private network. It only has port 80 open, so even though there's a (default) username & password for accessing it through SSH, that port won't be open.

> TODO elaborate on the network config? Explain that this is probably a spoke in the hub-spoke setup etc.

```shell
az deployment group create -g $RG_ON_PREM -f assets/odata-server.bicep
```

## Open the private link service

Now we have a data source that can only be accessed through a private ip, we can set up an [Azure Private Link Service](TODO). Currently Private Link Service requires access to a data source through an (internal) [Azure Load Balancer](TODO). Before we start creating these resources let's create a separate resource group.

```shell
RG_PL_SVC=rg-plink-service
az group create -n $RG_PL_SVC -l $LOCATION
```

In order to simulate a more realistic situation, we'll set up the Load Balancer in a new Virtual Network that's peered to the on premises network.

```shell
az deployment group create -g $RG_PL_SVC -f assets/vnet-peering.bicep
```

Note that the subnet that's going to be used for the Private Link Service will have to have its `privateLinkServiceNetworkPolicies` attribute set to `false`, which is done automatically by the command above.

## Connect through the private endpint

> TODO ADF managed vnet
