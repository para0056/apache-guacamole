#!/bin/bash

# ===================================================================
# Purpose:      An automation script for Apache Guacamole and its required components.
# Details:      This script automates the installation of the following components:
#                    - Nginx (reverse proxy for Apache Guacamole)
#                    - Certbot (client used to obtain a Let's Encrypt SSL certificate for Nginx)
#                    - MySQL (one of many possible databases compatible with Apache Guacamole)
#                    - Tomcat (used to host the Apache Guacamole client/web front end)
#                    - Guacd (the server component of Apache Guacamole)
#                    - Various other dependencies
# Github:       https://github.com/jasonvriends
# ===================================================================
#
# entrypoint.sh [(--help)] [(--guacamole)] [(--guacamole-version string)] [(--nginx)] [(--ssl)] [(--ssl-email) string] [(--ssl-domain) string] [(--mysql)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]
#
# Options:
#
# --help                        : Displays this help information.
# --guacamole                   : Installs Apache Guacamole.
# --guacamole-version           : Specify the Apache Guacamole version (if not specified the default is 1.0.0).
# --nginx                       : Installs nginx and fronts Apache Guacamole with a friendly url.
# --ssl                         : Installs a Let's Encrypt SSL certificate into Nginx.
#   --ssl-email string          : Email address used for Let's Encrypt renewal reminders.
#   --ssl-domain string         : The domain name used to generate the certificate signing request.
# --mysql                       : Installs mySQL for database authentication, load balancing groups, and web-based administration.
#   --mysql-root-pwd string     : The root mySQL password.
#   --mysql-db-name string      : mySql database to create for Apache Guacamole.
#   --mysql-db-user string      : mySql user to assign to the database.
#   --mysql-db-user-pwd string  : mySql user password.
# 
# Usage example(s): 
#
# Apache Guacamole: standalone
# ./entrypoint.sh --guacamole"
#
# Apache Guacamole: standalone + mySQL authentication)
# ./entrypoint.sh --guacamole" --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
#
# Apache Guacamole: Nginx + mySQL authentication
# ./entrypoint.sh --guacamole" --nginx --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
#
# Apache Guacamole: Nginx + Let's Encrypt SSL + mySQL authentication
# ./entrypoint.sh --guacamole" --nginx --ssl --ssl-email address@domain.com --ssl-domain domain.com --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
# ===================================================================

# Define help function
function help(){
    echo -e "entrypoint.sh - An automation script for installing Apache Guacamole and its required components."
    echo -e ""
    echo -e "This script automates the installation of the following components:"
    echo -e "- Nginx (reverse proxy for Apache Guacamole)"
    echo -e "- Certbot (client used to obtain a Let's Encrypt SSL certificate for Nginx)"
    echo -e "- MySQL (one of many possible databases compatible with Apache Guacamole)"
    echo -e "- Tomcat (used to host the Apache Guacamole client/web front end)"
    echo -e "- Guacd (the server component of Apache Guacamole)"
    echo -e "- Various other dependencies"
    echo -e ""
    echo -e "entrypoint.sh [(--help)] [(--guacamole)] [(--nginx)] [(--ssl)] [(--ssl-email) string] [(--ssl-domain) string] [(--mysql)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]"
    echo -e ""
    echo -e "Options:"
    echo -e "--help: Displays this help information."
    echo -e "--guacamole: installs Apache Guacamole"
    echo -e "--guacamole-version: Specify the Apache Guacamole version (if not specified the default is 1.0.0)."
    echo -e "--nginx: installs nginx and fronts Apache Guacamole with a friendly url."
    echo -e "--ssl: installs a Let's Encrypt SSL certificate on Nginx (requires Nginx option)."
    echo -e "  --ssl-email string: email address used for Let's Encrypt renewal reminders."
    echo -e "  --ssl-domain string: the domain name used to generate the certificate signing request."
    echo -e "--mysql: installs mySQL for database authentication, load balancing groups, and web-based administration."
    echo -e "  --mysql-root-pwd string: the root mySQL password."
    echo -e "  --mysql-db-name string: mysql database to create for Apache Guacamole."
    echo -e "  --mysql-db-user string: mysql user to assign to the database."
    echo -e "  --mysql-db-user-pwd string: mysql user password."
    echo -e ""
    echo -e "Usage examples:"
    echo -e ""
    echo -e "Apache Guacamole: standalone"
    echo -e "./entrypoint.sh --guacamole"
    echo -e ""
    echo -e "Apache Guacamole: standalone + mySQL authentication)"
    echo -e "./entrypoint.sh --guacamole --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    echo -e ""
    echo -e "Apache Guacamole: Nginx + mySQL authentication"
    echo -e "./entrypoint.sh --guacamole --nginx --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    echo -e ""
    echo -e "Apache Guacamole: Nginx + Let's Encrypt SSL + mySQL authentication"
    echo -e "./entrypoint.sh --guacamole --nginx --ssl --ssl-email address@domain.com --ssl-domain domain.com --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    exit 1
}

# Initalize variables.
nginx=0
ssl=0
mysql=0
guacamole=0
scripterror=0
color_yellow='\033[1;33m'
color_blue='\033[0;34m'
color_red='\033[0;31m'
color_green='\033[0;32m'
color_none='\033[0m'
export script_path="$( dirname "${BASH_SOURCE[0]}" )"
export guacamole_version="1.0.0"
export download_location="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${guacamole_version}"

# Read script arguments
echo -e "$(date "+%F %T") ${color_yellow}Read script arguments.${color_none}"

while [ "$1" != "" ]; do
    case $1 in
        --help              )   help
                                ;;
        --guacamole         )   guacamole=1
                                ;;
        --guacamole-version )   shift
                                guacamole_version="$1"
                                ;;
        --nginx             )   nginx=1
                                ;;
        --ssl               )   ssl=1
                                ;;
        --ssl-email         )   shift 
                                ssl_email="$1"
                                ;;
        --ssl-domain        )   shift 
                                ssl_domain="$1"
                                ;;
        --mysql             )   mysql=1 ;;
        --mysql-root-pwd    )   shift 
                                mysql_root_pwd="$1"
                                ;;
        --mysql-db-name     )   shift 
                                mysql_db_name="$1"
                                ;;
        --mysql-db-user     )   shift 
                                mysql_db_user="$1"
                                ;;
        --mysql-db-user-pwd )   shift 
                                mysql_db_user_pwd="$1"
                                ;;
    esac
    shift
done

# Verification
echo -e "$(date "+%F %T") ${color_yellow}Verification.${color_none}"

## --nginx || --mysql || --guacamole
if [ "$nginx" -eq "0" ] && [ "$mysql" -eq "0" ] && [ "$guacamole" -eq "0" ]; then
    clear
    help
fi

## nginx-install.sh present
if [ ! -f $script_path/nginx-install.sh ]; then
    echo -e "$(date "+%F %T") ${color_red}./nginx-install.sh not found.${color_none}"
    scripterror=1
fi

## nginx-ssl-install.sh present
if [ ! -f $script_path/nginx-ssl-install.sh ]; then
    echo -e "$(date "+%F %T") ${color_red}./nginx-ssl-install.sh not found.${color_none}"
    scripterror=1
fi

## mysql-install.sh present
if [ ! -f $script_path/mysql-install.sh ]; then
    echo -e "$(date "+%F %T") ${color_red}./mysql-install.sh not found.${color_none}"
    scripterror=1
fi

## guacamole-install.sh present
if [ ! -f $script_path/guacamole-install.sh ]; then
    echo -e "$(date "+%F %T") ${color_red}./guacamole-install.sh not found.${color_none}"
    scripterror=1
fi

## --ssl-email && --ssl-domain empty not empty with --ssl
if [ "$nginx" -eq "1" ] && [ "$ssl" -eq "1" ]; then
    if [ -z "$ssl_email" ] || [ -z "$ssl_domain" ]; then
        echo -e "$(date "+%F %T") ${color_red}--ssl specified but --ssl-email || --ssl-domain empty.${color_none}"
        scripterror=1
    fi
fi

## --mysql-root-pwd && --mysql-db-name && --mysql-db-user && --mysql-db-user-pwd not empty with --mysql
if [ "$mysql" -eq "1" ]; then
    if [ -z "$mysql_root_pwd" ] || [ -z "$mysql_db_name" ] || [ -z "$mysql_db_user" ] || [ -z "$mysql_db_user_pwd" ]; then
        echo -e "$(date "+%F %T") ${color_red}--mysql specified but --mysql-root-pwd || --mysql-db-name || --mysql-db-user || --mysql-db-user-pwd empty.${color_none}"
        scripterror=1
    fi
fi

## Exit on any script errors
if [ "$scripterror" -eq "1" ]; then
    exit 1
fi
 
# Proceed with the installation of Apache Guacamole with the following options
echo -e "$(date "+%F %T") ${color_green}entrypoint.sh${color_none} executed with the following options:"
echo -e "$(date "+%F %T") --guacamole=${color_yellow}$guacamole${color_none}"
echo -e "$(date "+%F %T") --nginx=${color_yellow}$nginx${color_none}"
echo -e "$(date "+%F %T") --ssl=${color_yellow}$ssl${color_none}"
echo -e "$(date "+%F %T")   --ssl-email=${color_yellow}$ssl_email${color_none}"
echo -e "$(date "+%F %T")   --ssl-domain=${color_yellow}$ssl_domain${color_none}"
echo -e "$(date "+%F %T") --mysql=${color_yellow}$mysql${color_none}"
echo -e "$(date "+%F %T")   --mysql-root-pwd=${color_yellow}$mysql_root_pwd${color_none}"
echo -e "$(date "+%F %T")   --mysql-db-name=${color_yellow}$mysql_db_name${color_none}"
echo -e "$(date "+%F %T")   --mysql-db-user=${color_yellow}$mysql_db_user${color_none}"
echo -e "$(date "+%F %T")   --mysql-db-user-pwd=${color_yellow}$mysql_db_user_pwd${color_none}"

# Install Nginx
if [ "$nginx" -eq "1" ]; then
    echo -e "$(date "+%F %T") ${color_yellow}Installing Nginx.${color_none}"
    $script_path/nginx-install.sh
fi

# Install Let's Encrypt SSL certificate
if [ "$nginx" -eq "1" ] && [ "$ssl" -eq "1" ]; then

    echo -e "$(date "+%F %T") ${color_yellow}Installing Let's Encrypt SSL certificate.${color_none}"
    $script_path/nginx-ssl-install.sh --ssl-email "$ssl_email" --ssl-domain "$ssl_domain"

fi

# Install mySQL
if [ "$mysql" -eq "1" ]; then
    
    echo -e "$(date "+%F %T") ${color_yellow}Installing mySQL.${color_none}"
    $script_path/mysql-install.sh --mysql-root-pwd "$mysql_root_pwd" --mysql-db-name "$mysql_db_name" --mysql-db-user "$mysql_db_user" --mysql-db-user-pwd "$mysql_db_user_pwd"

fi

# Install Apache Guacamole
if [ "$guacamole" -eq "1" ]; then

    echo -e "$(date "+%F %T") ${color_yellow}Installing Apache Guacamole${color_none}"
    $script_path/guacamole-install.sh

fi
