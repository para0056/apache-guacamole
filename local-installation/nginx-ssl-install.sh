#!/bin/bash

# ===================================================================
# Purpose:      An automation script to install a Let's Encrypt SSL certificate support of Apache Guacamole.
# Details:      This script automates the installation of a Let's Encrypt SSL certificate into Nginx.
# Github:       https://github.com/jasonvriends
# ===================================================================
# Syntax:
#
# --help                     : Displays this help information.
# --ssl-email string         : email address used for Let's Encrypt renewal reminders.
# --ssl-domain string        : the domain name used to generate the certificate signing request.
# 
# Examples: 
#
#   ./nginx-ssl-install.sh --ssl-email address@domain.com --ssl-domain domain.com
# ===================================================================

# Define help function
function help(){
    echo "nginx-ssl-install.sh - An automation script to install a Let's Encrypt SSL certificate support of Apache Guacamole.";
    echo "";
    echo "This script automates the installation of a Let's Encrypt SSL certificate into Nginx.";
    echo "";
    echo "Usage example:";
    echo "apache-guacamole [(--help)] [(--ssl-email) string] [(--ssl-domain) string]";
    echo "";
    echo "Options:";
    echo "--help: Displays this help information.";
    echo "--ssl-email string: email address used for Let's Encrypt renewal reminders.";
    echo "--ssl-domain string: the domain name used to generate the certificate signing request.";
    echo "";
    echo "Examples:";
    echo "";
    echo "./nginx-ssl-install.sh --ssl-email address@domain.com --ssl-domain domain.com";
    exit 1;
}

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

# Proceed with the installation of Apache Guacamole with the following options
echo "$(date "+%F %T") nginx-ssl-install.sh executed with the following options:";
echo "--ssl-email=$ssl_email";
echo "--ssl-domain=$ssl_domain";
echo "";

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

# Stop Nginx
systemctl stop nginx

# Generate and Install a Let's Encrypt SSL certificate into Nginx
certbot --nginx -n --email $ssl_email -d $ssl_domain --agree-tos --redirect --hsts

# Start Nginx
systemctl start nginx