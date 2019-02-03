#!/bin/bash

# ===================================================================
# Purpose:      An automation script to install Nginx in support of Apache Guacamole.
# Details:      This script automates the installation Nginx.
# Github:       https://github.com/jasonvriends
# ===================================================================
# Options:
#
# --help                     : Displays this help information.
# 
# Usage example(s): 
#
# ./nginx-install.sh
# ===================================================================

# Define help function
function help(){
    echo "nginx-install.sh - An automation script to install Nginx in support of Apache Guacamole."
    echo ""
    echo "This script automates the installation Nginx."
    echo ""
    echo "nginx-install.sh [(--help)]"
    echo ""
    echo "Options:"
    echo "--help: Displays this help information."
    echo ""
    echo "Usage examples:"
    echo ""
    echo "./nginx-install.sh"
    exit 1
}

# Initalize variables.
while [ "$1" != "" ]; do
    case $1 in
        --help )                help
                                ;;
    esac
    shift
done

# Update package lists
apt-get update

# Install Nginx
apt-get install nginx -y

# Configure Nginx

## Disable the default server block
rm /etc/nginx/sites-enabled/default

## Create server block with Apache Guacamole
echo "server {" > /etc/nginx/sites-available/apache-guacamole
echo " " >> /etc/nginx/sites-available/apache-guacamole
echo "    listen 80 default_server;" >> /etc/nginx/sites-available/apache-guacamole
echo "    listen [::]:80 default_server;" >> /etc/nginx/sites-available/apache-guacamole
echo "    root /var/www/html;" >> /etc/nginx/sites-available/apache-guacamole
echo "    index index.html index.htm index.nginx-debian.html;" >> /etc/nginx/sites-available/apache-guacamole
echo "    server_name \$hostname;" >> /etc/nginx/sites-available/apache-guacamole
echo "    location / {" >> /etc/nginx/sites-available/apache-guacamole
echo "        proxy_pass http://localhost:8080/guacamole;" >> /etc/nginx/sites-available/apache-guacamole
echo "        proxy_buffering off;" >> /etc/nginx/sites-available/apache-guacamole
echo "        proxy_http_version 1.1;" >> /etc/nginx/sites-available/apache-guacamole
echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> /etc/nginx/sites-available/apache-guacamole
echo "        proxy_set_header Upgrade \$http_upgrade;" >> /etc/nginx/sites-available/apache-guacamole
echo "        proxy_set_header Connection \$http_connection;" >> /etc/nginx/sites-available/apache-guacamole
echo "        access_log off;" >> /etc/nginx/sites-available/apache-guacamole
echo "    }" >> /etc/nginx/sites-available/apache-guacamole
echo " " >> /etc/nginx/sites-available/apache-guacamole
echo "}" >> /etc/nginx/sites-available/apache-guacamole

## Activate server block for Apache Guacamole
ln -s /etc/nginx/sites-available/apache-guacamole /etc/nginx/sites-enabled/apache-guacamole

# Restart Nginx
systemctl restart nginx