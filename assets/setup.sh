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
PL_SVC_NAME=`echo "$OUTPUTS" | jq -r .plsName.value`
PL_SVC_ID=`echo "$OUTPUTS" | jq -r .plsId.value`
PL_SVC_FQDNS=`echo "$OUTPUTS" | jq -r .plsFqdns.value`


az network nic ip-config update --ids $PROXY_IP_CONFIG_ID --lb-name $LB_NAME --lb-address-pools $POOL_NAME


az deployment group create -g $RG_PL_EP -f pl-endpoint.bicep \
  --parameters \
    privateLinkServiceId=$PL_SVC_ID \
    privateLinkServiceFqdns=$PL_SVC_FQDNS \
  --query properties.outputs


PL_EP_NAME=`az network private-link-service show --ids $PL_SVC_ID --query privateEndpointConnections[0].name -o tsv`

az network private-link-service connection update -g $RG_PL_SVC -n $PL_EP_NAME --service-name $PL_SVC_NAME --connection-status Approved 