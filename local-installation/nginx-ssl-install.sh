#!/bin/bash

# ===================================================================
# Purpose:      An automation script to install a Let's Encrypt SSL certificate into Nginx in support of Apache Guacamole.
# Details:      This script automates the installation of a Let's Encrypt SSL certificate into Nginx.
# Github:       https://github.com/jasonvriends
# ===================================================================
#
# ./nginx-ssl-install.sh [(--help)] [(--ssl-email) string] [(--ssl-domain) string]
#
# Options:
#
# --help                     : Displays this help information.
# --ssl-email string         : email address used for Let's Encrypt renewal reminders.
# --ssl-domain string        : the domain name used to generate the certificate signing request.
# 
# Usage example(s): 
#
# ./nginx-ssl-install.sh --ssl-email johndoe@gmail.com --ssl-domain mydomain.com
# ===================================================================

# Define help function
function help(){
    echo "nginx-ssl-install.sh - An automation script to install a Let's Encrypt SSL certificate into Nginx in support of Apache Guacamole."
    echo ""
    echo "This script automates the installation of a Let's Encrypt SSL certificate into Nginx."
    echo ""
    echo "./nginx-ssl-install.sh [(--help)] [(--ssl-email) string] [(--ssl-domain) string]"
    echo ""
    echo "Options:"
    echo "--help: Displays this help information."
    echo "--ssl-email string: email address used for Let's Encrypt renewal reminders."
    echo "--ssl-domain string: the domain name used to generate the certificate signing request."
    echo ""
    echo "Usage example:"
    echo "./nginx-ssl-install.sh --ssl-email johndoe@gmail.com --ssl-domain mydomain.com"
    exit 1
}

# Initalize variables.
color_yellow='\033[1;33m'
color_blue='\033[0;34m'
color_red='\033[0;31m'
color_green='\033[0;32m'
color_none='\033[0m'

# Verify exported variables
if [ -z "$guacamole_version" ] || [ -z "$download_location" ] || [ -z "$script_path" ] [ -z "$download_path" ]; then
    echo "$(date "+%F %T") ${color_red}exported variables from entrypoint.sh missing.${color_none}"
    exit 1
fi

# Read script arguments
while [ "$1" != "" ]; do
    case $1 in
        --help )                help
                                ;;
        --ssl-email )           shift 
                                ssl_email="$1"
                                ;;
        --ssl-domain )          shift 
                                ssl_domain="$1"
                                ;;
    esac
    shift
done

# Check for empty positional parameters
if [ -z "$ssl_email" ] || [ -z "$ssl_domain" ]; then
    echo "ERROR: --ssl-email and/or --ssl-domain empty."
    exit 1
fi

# Proceed with the installation of Apache Guacamole with the following options
echo "$(date "+%F %T") nginx-ssl-install.sh executed with the following options:"
echo "--ssl-email=$ssl_email"
echo "--ssl-domain=$ssl_domain"
echo ""

# Certbot

## Update package lists
apt-get update

## Add Certbot repository
add-apt-repository ppa:certbot/certbot -y

## Update package lists
apt-get update

## Install Certbot
apt-get install python-certbot-nginx -y

# Nginx 

## Replace server block with Apache Guacamole
echo "server {" > /etc/nginx/sites-available/apache-guacamole
echo " " >> /etc/nginx/sites-available/apache-guacamole
echo "    listen 80 default_server;" >> /etc/nginx/sites-available/apache-guacamole
echo "    listen [::]:80 default_server;" >> /etc/nginx/sites-available/apache-guacamole
echo "    root /var/www/html;" >> /etc/nginx/sites-available/apache-guacamole
echo "    index index.html index.htm index.nginx-debian.html;" >> /etc/nginx/sites-available/apache-guacamole
echo "    server_name $ssl_domain;" >> /etc/nginx/sites-available/apache-guacamole
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

## Stop Nginx
systemctl stop nginx

## Generate and Install a Let's Encrypt SSL certificate for Nginx
certbot --nginx -n --email $ssl_email --domain $ssl_domain --agree-tos --redirect --hsts

## Start Nginx
systemctl start nginx