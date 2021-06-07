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

OUTPUTS=`az deployment group create -g $RG_PL_SVC \
  -f pl-service.bicep \
  --parameters \
    vmOnPremIp=$SRC_VM_IP \
    vnetOnPremId=$VNET_ON_PREM_ID \
    vnetOnPremName=$VNET_ON_PREM_NAME \
    rgOnPremName=$RG_ON_PREM \
  --query properties.outputs`

LB_NAME=`echo "$OUTPUTS" | jq -r .lbName.value`
POOL_NAME=`echo "$OUTPUTS" | jq -r .poolName.value`
PROXY_IP_CONFIG_ID=`echo "$OUTPUTS" | jq -r .ipConfigId.value`

az network nic ip-config update --ids $PROXY_IP_CONFIG_ID --lb-name $LB_NAME --lb-address-pools $POOL_NAME