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
# entrypoint.sh [(--help)] [(--apache-guacamole)] [(--nginx)] [(--ssl)] [(--ssl-email) string] [(--ssl-domain) string] [(--mysql)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]
#
# Options:
#
# --help                       : Displays this help information.
# --apache-guacamole           : installs Apache Guacamole.
# --nginx                      : installs nginx and fronts Apache Guacamole with a friendly url.
# --ssl                        : installs a Let's Encrypt SSL certificate on Nginx (requires Nginx option).
#   --ssl-email string         : email address used for Let's Encrypt renewal reminders.
#   --ssl-domain string        : the domain name used to generate the certificate signing request.
# --mysql                      : installs mySQL for database authentication, load balancing groups, and web-based administration.
#   --mysql-root-pwd string    : the root mySQL password.
#   --mysql-db-name string     : mysql database to create for Apache Guacamole.
#   --mysql-db-user string     : mysql user to assign to the database.
#   --mysql-db-user-pwd string : mysql user password.
# 
# Usage example(s): 
#
# Apache Guacamole: standalone
# ./entrypoint.sh --apache-guacamole"
#
# Apache Guacamole: standalone + mySQL authentication)
# ./entrypoint.sh --apache-guacamole" --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
#
# Apache Guacamole: Nginx + mySQL authentication
# ./entrypoint.sh --apache-guacamole" --nginx --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
#
# Apache Guacamole: Nginx + Let's Encrypt SSL + mySQL authentication
# ./entrypoint.sh --apache-guacamole" --nginx --ssl --ssl-email address@domain.com --ssl-domain domain.com --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
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
    echo -e "entrypoint.sh [(--help)] [(--apache-guacamole)] [(--nginx)] [(--ssl)] [(--ssl-email) string] [(--ssl-domain) string] [(--mysql)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]"
    echo -e ""
    echo -e "Options:"
    echo -e "--help: Displays this help information."
    echo -e "--apache-guacamole: installs Apache Guacamole"
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
    echo -e "./entrypoint.sh --apache-guacamole"
    echo -e ""
    echo -e "Apache Guacamole: standalone + mySQL authentication)"
    echo -e "./entrypoint.sh --apache-guacamole --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    echo -e ""
    echo -e "Apache Guacamole: Nginx + mySQL authentication"
    echo -e "./entrypoint.sh --apache-guacamole --nginx --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    echo -e ""
    echo -e "Apache Guacamole: Nginx + Let's Encrypt SSL + mySQL authentication"
    echo -e "./entrypoint.sh --apache-guacamole --nginx --ssl --ssl-email address@domain.com --ssl-domain domain.com --mysql --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    exit 1
}

# Initalize variables.
nginx=0
ssl=0
mysql=0
apache_guacamole=0
export apache_guacamole_version="1.0.0"
export download_location="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${apache_guacamole_version}"

# Read script arguments
while [ "$1" != "" ]; do
    case $1 in
        --help              )           help
                                        ;;
        --apache-guacamole  )           apache_guacamole=1
                                        ;;
        --apache-guacamole-version  )   shift
                                        apache_guacamole_version="$1"
                                        ;;
        --nginx             )           nginx=1
                                        ;;
        --ssl               )           ssl=1
                                        ;;
        --ssl-email         )           shift 
                                        ssl_email="$1"
                                        ;;
        --ssl-domain        )           shift 
                                        ssl_domain="$1"
                                        ;;
        --mysql             )           mysql=1 ;;
        --mysql-root-pwd    )           shift 
                                        mysql_root_pwd="$1"
                                        ;;
        --mysql-db-name     )           shift 
                                        mysql_db_name="$1"
                                        ;;
        --mysql-db-user     )           shift 
                                        mysql_db_user="$1"
                                        ;;
        --mysql-db-user-pwd )           shift 
                                        mysql_db_user_pwd="$1"
                                        s6;;
    esac
    shift
done

# Verify variables.
if [ "$nginx" -eq "0" ] && [ "$mysql" -eq "0" ] && [ "$apache_guacamole" -eq "0" ]; then
    help
fi

# Proceed with the installation of Apache Guacamole with the following options
echo -e "entrypoint.sh executed with the following options:"
echo -e "--apache-guacamole=$apache_guacamole"
echo -e "--nginx=$nginx"
echo -e "--ssl=$ssl"
echo -e "  --ssl-email=$ssl_email"
echo -e "  --ssl-domain=$ssl_domain"
echo -e "--mysql=$mysql"
echo -e "  --mysql-root-pwd=$mysql_root_pwd"
echo -e "  --mysql-db-name=$mysql_db_name"
echo -e "  --mysql-db-user=$mysql_db_user"
echo -e "  --mysql-db-user-pwd=$mysql_db_user_pwd"
echo -e ""

# Install Nginx
if [ "$nginx" -eq "1" ]; then

    echo -e "Installing Nginx."

    # Check for installation script
    if [ ! -f ./nginx-install.sh ]; then

        echo -e "./nginx-install.sh not found. Downloading from https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/nginx-install.sh"

            wget -q --show-progress -O "https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/nginx-install.sh"
            if [ $? -ne 0 ]; then
                echo "Failed to download https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/nginx-install.sh"
                exit 1
            else
                ./nginx-install.sh
                echo -e ""
            fi

    else

        ./nginx-install.sh
        echo -e ""

    fi

fi

# Install Let's Encrypt SSL certificate
if [ "$nginx" -eq "1" ] && [ "$ssl" -eq "1" ]; then

    echo -e "Installing Let's Encrypt SSL certificate."

    # Check for empty positional parameters
    if [ -z "$ssl_email" ] || [ -z "$ssl_domain" ]; then
        echo -e "--ssl specified but --ssl-email or --ssl-domain empty."
        exit 1
    fi

    # Check for installation script
    if [ ! -f ./nginx-ssl-install.sh ]; then

        echo -e "./nginx-ssl-install.sh not found. Downloading from https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/nginx-ssl-install.sh"

            wget -q --show-progress -O "https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/nginx-ssl-install.sh"
            if [ $? -ne 0 ]; then
                echo "Failed to download https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/nginx-ssl-install.sh"
                exit 1
            else
                ./nginx-ssl-install.sh --ssl-email "$ssl_email" --ssl-domain "$ssl_domain"
                echo -e ""
            fi

    else

        ./nginx-ssl-install.sh --ssl-email "$ssl_email" --ssl-domain "$ssl_domain"
        echo -e ""

    fi

fi

# Install mySQL
if [ "$mysql" -eq "1" ]; then
    
    echo -e "Installing mySQL."

    # Check for empty positional parameters
    if [ -z "$mysql_root_pwd" ] || [ -z "$mysql_db_name" ] || [ -z "$mysql_db_user" ] || [ -z "$mysql_db_user_pwd" ]; then
        echo -e "--mysql specified but --mysql-root-pwd, --mysql-db-name, --mysql-db-user, or --mysql-db-user-pwd empty."
        exit 1
    fi

    # Check for installation script
    if [ ! -f ./mysql-install.sh ]; then

        echo -e "./mysql-install.sh not found. Downloading from https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/mysql-install.sh"

            wget -q --show-progress -O "https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/mysql-install.sh"
            if [ $? -ne 0 ]; then
                echo "Failed to download https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/mysql-install.sh"
                exit 1
            else
                ./mysql-install.sh --mysql-root-pwd "$mysql_root_pwd" --mysql-db-name "$mysql_db_name" --mysql-db-user "$mysql_db_user" --mysql-db-user-pwd "$mysql_db_user_pwd"
                echo -e ""
            fi

    else

        ./mysql-install.sh --mysql-root-pwd "$mysql_root_pwd" --mysql-db-name "$mysql_db_name" --mysql-db-user "$mysql_db_user" --mysql-db-user-pwd "$mysql_db_user_pwd"

        echo -e ""
    fi

fi

# Install Apache Guacamole
if [ "$apache_guacamole" -eq "1" ]; then

echo -e "Installing Apache Guacamole"

    # Check for empty positional parameters
    if [ -z "$apache_guacamole_version" ]; then
        echo -e "--apache-guacamole specified but --apache-guacamole-version empty."
        exit 1
    fi

    # Check for installation script
    if [ ! -f ./guacamole-install.sh ]; then

        echo -e "./guacamole-install.sh not found. Downloading from https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/guacamole-install.sh"

            wget -q --show-progress -O "https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/guacamole-install.sh"
            if [ $? -ne 0 ]; then
                echo "Failed to download https://raw.githubusercontent.com/jasonvriends/apache-guacamole/master/local-installation/guacamole-install.sh"
                exit 1
            else
                ./guacamole-install.sh"
                echo -e ""
            fi        

    else

        ./guacamole-install.sh"
        echo -e ""

    fi

fi
