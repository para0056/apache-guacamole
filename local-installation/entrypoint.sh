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
# Syntax:
#
# --help                     : Displays this help information.
# --nginx                    : installs nginx and fronts Apache Guacamole with a friendly url.
# --ssl                      : installs a Let's Encrypt SSL certificate on Nginx (requires Nginx option).
# --ssl-email string         : email address used for Let's Encrypt renewal reminders.
# --ssl-domain string        : the domain name used to generate the certificate signing request.
# --mysql                    : installs mySQL for database authentication, load balancing groups, and web-based administration.
# --mysql-root-pwd string    : the root mySQL password.
# --mysql-db-name string     : mysql database to create for Apache Guacamole.
# --mysql-db-user string     : mysql user to assign to the database.
# --mysql-db-user-pwd string : mysql user password.
# 
# Examples: 
#
#   Apache Guacamole: standalone
#   ./entrypoint.sh
#
#   Apache Guacamole: standalone + mySQL authentication)
#   ./entrypoint.sh --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
#
#   Apache Guacamole: Nginx + mySQL authentication
#   ./entrypoint.sh --nginx --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
#
#   Apache Guacamole: Nginx + Let's Encrypt SSL + mySQL authentication
#   ./entrypoint.sh --nginx --ssl --ssl-email address@domain.com --ssl-domain domain.com --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
# ===================================================================

# Define help function
function help(){
    echo "entrypoint.sh - An automation script for installing Apache Guacamole and its required components.";
    echo "";
    echo "This script automates the installation of the following components:";
    echo "- Nginx (reverse proxy for Apache Guacamole)";
    echo "- Certbot (client used to obtain a Let's Encrypt SSL certificate for Nginx)";
    echo "- MySQL (one of many possible databases compatible with Apache Guacamole)";
    echo "- Tomcat (used to host the Apache Guacamole client/web front end)";
    echo "- Guacd (the server component of Apache Guacamole)";
    echo "- Various other dependencies";
    echo "";
    echo "Usage example:";
    echo "apache-guacamole [(--help)] [(--nginx)] [(--ssl)] [(--ssl-email) string] [(--ssl-domain) string] [(--mysql)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]";
    echo "";
    echo "Options:";
    echo "--help: Displays this help information.";
    echo "--nginx: installs nginx and fronts Apache Guacamole with a friendly url.";
    echo "--ssl: installs a Let's Encrypt SSL certificate on Nginx (requires Nginx option).";
    echo "--ssl-email string: email address used for Let's Encrypt renewal reminders.";
    echo "--ssl-domain string: the domain name used to generate the certificate signing request.";
    echo "--mysql: installs mySQL for database authentication, load balancing groups, and web-based administration.";
    echo "--mysql-root-pwd string: the root mySQL password.";
    echo "--mysql-db-name string: mysql database to create for Apache Guacamole.";
    echo "--mysql-db-user string: mysql user to assign to the database.";
    echo "--mysql-db-user-pwd string: mysql user password.";
    echo "";
    echo "Examples:";
    echo "";
    echo "Apache Guacamole: standalone";
    echo "./entrypoint.sh";
    echo "";
    echo "Apache Guacamole: standalone + mySQL authentication)";
    echo "./entrypoint.sh --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2";
    echo "";
    echo "Apache Guacamole: Nginx + mySQL authentication";
    echo "./entrypoint.sh --nginx --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2";
    echo "";
    echo "Apache Guacamole: Nginx + Let's Encrypt SSL + mySQL authentication";
    echo "./entrypoint.sh --nginx --ssl --ssl-email address@domain.com --ssl-domain domain.com --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2";
    exit 1;
}

# Initalize variables to 0.
nginx=0;
ssl=0;
mysql=0;

while [ "$1" != "" ]; do
    case $1 in
        --help )                help
                                ;;
        --nginx )               nginx=1
                                ;;
        --ssl )                 ssl=1
                                ;;
        --ssl-email )           shift 
                                ssl_email="$1"
                                ;;
        --ssl-domain )          shift 
                                ssl_domain="$1"
                                ;;
        --mysql )               mysql=1 ;;
        --mysql-root-pwd )      shift 
                                mysql_root_pwd="$1"
                                ;;
        --mysql-db-name )       shift 
                                mysql_db_name="$1"
                                ;;
        --mysql-db-user )       shift 
                                mysql_db_user="$1"
                                ;;
        --mysql-db-user-pwd )   shift 
                                mysql_db_user_pwd="$1"
                                ;;
    esac
    shift
done

# Proceed with the installation of Apache Guacamole with the following options
echo "$(date "+%F %T") entrypoint.sh executed with the following options:";
echo "--nginx=$nginx";
echo "--ssl=$ssl";
echo "  --ssl-email=$ssl_email";
echo "  --ssl-domain=$ssl_domain";
echo "--mysql=$mysql";
echo "  --mysql-root-pwd=$mysql_root_pwd";
echo "  --mysql-db-name=$mysql_db_name";
echo "  --mysql-db-user=$mysql_db_user";
echo "  --mysql-db-user-pwd=$mysql_db_user_pwd";
echo "";

# Installing Nginx
if [ "$nginx" -eq "1" ]; then

    echo "$(date "+%F %T") Installing Nginx."

    # Check for installation script
    if [ ! -f ./nginx-install.sh ]; then
        echo "Error: ./nginx-install.sh not found."
        exit 1;
    else
        ./nginx-install.sh
        echo "";
    fi

fi

# Installing Let's Encrypt SSL certificate
if [ "$nginx" -eq "1" ] && [ "$ssl" -eq "1" ]; then

    echo "$(date "+%F %T") Installing Let's Encrypt SSL certificate."

    # Check for empty positional parameters
    if [ -z "$ssl_email" ] || [ -z "$ssl_domain" ]; then
        echo "Error: --ssl specified but --ssl-email or --ssl-domain empty."
        exit 1
    fi

    # Check for installation script
    if [ ! -f ./nginx-ssl-install.sh ]; then
        echo "Error: ./nginx-ssl-install.sh not found."
        exit 1;
    else
        ./nginx-ssl-install.sh
        echo "";
    fi

fi

# Installing mySQL
if [ "$mysql" -eq "1" ]; then
    
    echo "$(date "+%F %T") Installing mySQL."

    # Check for empty positional parameters
    if [ -z "$mysql_root_pwd" ] || [ -z "$mysql_db_name" ] || [ -z "$mysql_db_user" ] || [ -z "$mysql_db_user_pwd" ]; then
        echo "Error: --mysql specified but --mysql-root-pwd, --mysql-db-name, --mysql-db-user, or --mysql-db-user-pwd empty."
        exit 1
    fi

    # Check for installation script
    if [ ! -f ./mysql-install.sh ]; then
        echo "Error: ./mysql-install.sh not found."
        exit 1;
    else
        ./mysql-install.sh
        echo "";
    fi

fi

# Installing Apache Guacamole

echo "$(date "+%F %T") Installing Apache Guacamole"

    # Check for installation script
    if [ ! -f ./guacamole-install.sh ]; then
        echo "Error: ./guacamole-install.sh not found."
        exit 1;
    else
        ./guacamole-install.sh
        echo "";
    fi
