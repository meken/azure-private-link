#!/bin/bash
RG_ON_PREM=
RG_PL_SVC=
RG_PL_EP=

LOCATION=westeurope

az group create -n $RG_ON_PREM -l $LOCATION

OUTPUTS=`az deployment group create -g $RG_ON_PREM -f on-prem-setup.bicep --query properties.outputs`

VNET_ON_PREM_NAME=`echo "$OUTPUTS" | jq -r .vnetName.value`
VNET_ON_PREM_ID=`echo "$OUTPUTS" | jq -r .vnetId.value`
SRC_VM_IP=`echo "$OUTPUTS" | jq -r .vmIp.value`

az group create -n $RG_PL_SVC -l $LOCATION

OUTPUTS=`az deployment group create -g $RG_PL_SVC -f pl-service-vnet.bicep --query properties.outputs`

VNET_PL_NAME=`echo "$OUTPUTS" | jq -r .vnetName.value`
VNET_PL_ID=`echo "$OUTPUTS" | jq -r .vnetId.value`
SUBNET_PL_ID=`echo "$OUTPUTS" | jq -r .subnetId.value`

az network vnet peering create \
  -n peer-on-prem-to-plink \
  -g $RG_ON_PREM \
  --vnet-name $VNET_ON_PREM_NAME \
  --remote-vnet $VNET_PL_ID \
  --allow-vnet-access \
  --query provisioningState \
  -o tsv

az network vnet peering create \
  -n peer-plink-to-on-prem \
  -g $RG_PL_SVC \
  --vnet-name $VNET_PL_NAME \
  --remote-vnet $VNET_ON_PREM_ID \
  --allow-vnet-access \
  --query provisioningState \
  -o tsv

az deployment group create \
  -g $RG_PL_SVC \
  -f pl-service.bicep \
  --parameters backendVmIp=$SRC_VM_IP \
    vnetOnPremId=$VNET_ON_PREM_ID \
    vnetPrivateLinkId=$VNET_PL_ID \
    subnetPrivateLinkId=$SUBNET_PL_ID