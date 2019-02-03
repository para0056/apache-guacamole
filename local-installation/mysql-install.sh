#!/bin/bash

# ===================================================================
# Purpose:      An automation script to install mySQL in support of Apache Guacamole.
# Details:      This script automates the installation of mySQL.
# Github:       https://github.com/jasonvriends
# ===================================================================
#
# mysql-install.sh [(--help)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]
#
# Options:
#
# --help                     : Displays this help information.
# --mysql-root-pwd string    : the root mySQL password.
# --mysql-db-name string     : mysql database to create for Apache Guacamole.
# --mysql-db-user string     : mysql user to assign to the database.
# --mysql-db-user-pwd string : mysql user password.
# 
# Usage example(s): 
#
#   ./mysql-install.sh --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2
# ===================================================================

# Define help function
function help(){
    echo "mysql-install.sh - An automation script to install mySQL in support of Apache Guacamole."
    echo ""
    echo "This script automates the installation of mySQL."
    echo ""
    echo "mysql-install.sh [(--help)] [(--mysql-root-pwd) string] [(--mysql-db-name) string] [(--mysql-db-user) string] [(--mysql-db-user-pwd) string]"
    echo ""
    echo "Options:"
    echo "--help: Displays this help information."
    echo "--mysql-root-pwd string    : the root mySQL password."
    echo "--mysql-db-name string     : mysql database to create for Apache Guacamole."
    echo "--mysql-db-user string     : mysql user to assign to the database."
    echo "--mysql-db-user-pwd string : mysql user password."
    echo ""
    echo "Usage example(s):"
    echo ""
    echo "./mysql-install.sh --mysql-root-pwd password1 --mysql-db-name guacamole_db --mysql-db-user guacamole_usr --mysql-db-user-pwd password2"
    exit 1
}

# Verify variables
if [ -z $apache_guacamole_version ] [ -z $download_location ]; then
    echo "ERROR: exported variables from entrypoint.sh missing."
    exit 1
fi

# Read script arguments
while [ "$1" != "" ]; do
    case $1 in
        --help )                help
                                ;;
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
echo "$(date "+%F %T") mysql-install.sh executed with the following options:"
echo "--mysql-root-pwd=$mysql_root_pwd"
echo "--mysql-db-name=$mysql_db_name"
echo "--mysql-db-user=$mysql_db_user"
echo "--mysql-db-user-pwd=$mysql_db_user_pwd"
echo "";

# Check for empty positional parameters
if [ -z "$mysql_root_pwd" ] || [ -z "$mysql_db_name" ] || [ -z "$mysql_db_user" ] || [ -z "$mysql_db_user_pwd" ]; then
    echo "ERROR: --mysql-root-pwd and/or --mysql-db-name and/or --mysql-db-user and/or --mysql-db-user-pwd empty."
    exit 1
fi

# mySQL
export DEBIAN_FRONTEND=noninteractive
echo mysql-server mysql-server/root_password password $mysql_root_pwd | debconf-set-selections
echo mysql-server mysql-server/root_password_again password $mysql_root_pwd | debconf-set-selections

## Install mySQL packages
apt-get install mysql-server mysql-client mysql-common mysql-utilities -y

## Create user
sql_query="create user '$mysql_db_user'@'localhost' identified by '$mysql_db_user_pwd';"
echo $sql_query | mysql -u root -p"$mysql_root_pwd"

## Create database
sql_query="create database $mysql_db_name;"
echo $sql_query | mysql -u root -p"$mysql_root_pwd"

## Grant the user privileges to the database
sql_query="GRANT SELECT,INSERT,UPDATE,DELETE ON $mysql_db_name.* TO $mysql_db_user@localhost; flush privileges;"
echo $sql_query | mysql -u root -p"$mysql_root_pwd"

## apply database schema

### download jdbc authentication extension
if [ ! -f guacamole-auth-jdbc-${apache_guacamole_version}.tar.gz ]; then

    wget -q --show-progress -O guacamole-auth-jdbc-${apache_guacamole_version}.tar.gz ${download_location}/binary/guacamole-auth-jdbc-${apache_guacamole_version}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Failed to download guacamole-auth-jdbc-${apache_guacamole_version}.tar.gz"
        echo "${download_location}/binary/guacamole-auth-jdbc-${apache_guacamole_version}.tar.gz"
        exit
    fi

fi

### Extract database schema
tar -xzf guacamole-auth-jdbc-${apache_guacamole_version}.tar.gz

### Apply database schema
cat guacamole-auth-jdbc-${apache_guacamole_version}/mysql/schema/*.sql | mysql -u root -p"$mysql_root_pwd" "$mysql_db_name"

# Configure guacamole.properties
echo "mysql-hostname: localhost" >> /etc/guacamole/guacamole.properties
echo "mysql-port: 3306" >> /etc/guacamole/guacamole.properties
echo "mysql-database: ${mysql_db_name}" >> /etc/guacamole/guacamole.properties
echo "mysql-username: ${mysql_db_user}" >> /etc/guacamole/guacamole.properties
echo "mysql-password: ${mysql_db_user_pwd}" >> /etc/guacamole/guacamole.properties
