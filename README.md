# Using Private Links to access on premises sources

The purpose of this repository is to illustrate how to set up a [Private Link](TODO) connection to access resources on private and/or on-premises networks. For the sake of the example we'll create an isolated virtual network to represent the private network. The end result will look like this:

![Final Architecture](./images/plinks-architecture.svg)

> TODO explain the picture.

## Mocking the on-premises environment

In order to mimic an on-prem data source, we'll create a new resource group with a new virtual network and put the VM that's going to host the OData service in that virtual network. All resources will be created in the same location as the resource group, so pick one that's the closest to you.

```shell
RG_ONPREM=rg-on-prem
az group create -n $RG_ONPREM -l westeurope
```

Once the resource group is ready, we can deploy the sample OData service. The command below will create a new VM (DS2_v3) with a reverse proxy to `https://services.odata.org/V3/Northwind/`, which is an online demo OData service. For the purposes of this example, just assume that the VM **is** the data source. And please note it can only be accessed through the private network. It only has port 80 open, so even though there's a (default) username & password for accessing it through SSH, that port is not open.

> TODO elaborate on the network config? Explain that this is probably a spoke in the hub-spoke setup etc.

```shell
az deployment group create -g $RG_ONPREM -f assets/odata-server.bicep
```

> TODO the script below needs to become part of the CustomScript extension

```shell
unlink /etc/nginx/sites-enabled/default

cat <<EOT >> /etc/nginx/sites-available/reverse-proxy.conf
server {
    listen 80;
    listen [::]:80;

    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location / {
        proxy_pass https://services.odata.org/V3/Northwind/;
    }
}
EOT

ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
```

## Open the private link service

Now we have a data source that can only be accessed through a private ip, we'll need to work on the first step of the two-step approach for enabling access through Azure Private Links.

> TODO vnet peering, resources (load balancer & private DNS zones) and the private link service

## Connect through the private endpint

> TODO ADF managed vnet
