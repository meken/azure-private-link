#!/bin/bash

apt update && apt install -y nginx

unlink /etc/nginx/sites-enabled/default

TARGET="$1"

cat <<EOT >> /etc/nginx/sites-available/reverse-proxy.conf
server {
    listen 80;
    listen [::]:80;

    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location / {
        proxy_pass $TARGET;
    }
}
EOT

ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf

service nginx reload
