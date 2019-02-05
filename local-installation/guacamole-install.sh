#!/bin/bash

# ===================================================================
# Purpose:      An automation script to install Apache Guacamole.
# Details:      This script automates the installation of Apache Guacamole.
# Github:       https://github.com/jasonvriends
# ===================================================================
# Options:
#
# --help                     : Displays this help information.
# 
# Usage example(s): 
#
# ./guacamole-install.sh
# ===================================================================

# Define help function
function help(){
    echo "guacamole-install.sh - An automation script to install Apache Guacamole."
    echo ""
    echo "This script automates the installation of Apache Guacamole."
    echo ""
    echo "guacamole-install.sh [(--help)]"
    echo ""
    echo "Options:"
    echo "--help: Displays this help information."
    echo ""
    echo "Usage examples:"
    echo ""
    echo "./guacamole-install.sh"
    exit 1
}

# Initalize variables.
color_yellow='\033[1;33m'
color_blue='\033[0;34m'
color_red='\033[0;31m'
color_green='\033[0;32m'
color_none='\033[0m'

# Verify exported variables
if [ -z $guacamole_version ] || [ -z $download_location ] || [ -z $script_path ]; then
    echo "$(date "+%F %T") ${color_red}exported variables from entrypoint.sh missing.${color_none}"
    exit 1
fi

# Read script arguments
while [ "$1" != "" ]; do
    case $1 in
        --help )                help
                                ;;
    esac
    shift
done

# Update package lists
apt-get update

# Ubuntu and Debian have different package names for libjpeg
# Ubuntu and Debian versions have differnet package names for libpng-dev
# Ubuntu 18.04 does not include universe repo by default
source /etc/os-release
if [[ "${NAME}" == "Ubuntu" ]]
then
    JPEGTURBO="libjpeg-turbo8-dev"
    if [[ "${VERSION_ID}" == "18.04" ]]
    then
        sed -i 's/bionic main$/bionic main universe/' /etc/apt/sources.list
    fi
    if [[ "${VERSION_ID}" == "16.04" ]]
    then
        LIBPNG="libpng12-dev"
    else
        LIBPNG="libpng-dev"
    fi
elif [[ "${NAME}" == *"Debian"* ]]
then
    JPEGTURBO="libjpeg62-turbo-dev"
    if [[ "${PRETTY_NAME}" == *"stretch"* ]]
    then
        LIBPNG="libpng-dev"
    else
        LIBPNG="libpng12-dev"
    fi
else
    echo "$(date "+%F %T") ${color_red}Unsupported Distro - Ubuntu or Debian Only${color_none}."
    exit 1
fi

# Update apt so we can search apt-cache for newest tomcat version supported
apt-get -qq update

# Tomcat 8.0.x is End of Life, however Tomcat 7.x is not...
# If Tomcat 8.5.x or newer is available install it, otherwise install Tomcat 7
# I have not testing with Tomcat9...
if [[ $(apt-cache show tomcat8 | egrep "Version: 8.[5-9]" | wc -l) -gt 0 ]]
then
    TOMCAT="tomcat8"
else
    TOMCAT="tomcat7"
fi

# Install features
echo -e "Installing dependencies. This might take a few minutes..."

apt-get -y install build-essential libcairo2-dev ${JPEGTURBO} ${LIBPNG} libossp-uuid-dev libavcodec-dev libavutil-dev \
libswscale-dev libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev \
libvorbis-dev libwebp-dev mysql-server mysql-client mysql-common mysql-utilities libmysql-java ${TOMCAT} freerdp-x11 \
ghostscript wget dpkg-dev

if [ $? -ne 0 ]; then
    echo -e "$(date "+%F %T") ${color_red}Failed${color_none}"
    exit 1
else
    echo -e "OK"
fi

# Download Apache Guacamole server
if [ ! -f $script_path/guacamole-server-${guacamole_version}.tar.gz ]; then

    wget -q --show-progress -O guacamole-server-${guacamole_version}.tar.gz ${download_location}/binary/guacamole-server-${guacamole_version}.tar.gz
    if [ $? -ne 0 ]; then
        echo "$(date "+%F %T") ${color_red}Failed to download $script_path/guacamole-server-${guacamole_version}.tar.gz${color_none}"
        echo "${download_location}/binary/guacamole-server-${guacamole_version}.tar.gz"
        exit
    fi

    ## Extract Guacamole files
    tar -xzf $script_path/guacamole-server-${guacamole_version}.tar.gz

fi

# Download Apache Guacamole client
if [ ! -f $script_path/guacamole-guacamole-${guacamole_version}.war ]; then

    wget -q --show-progress -O guacamole-guacamole-${guacamole_version}.war ${download_location}/binary/guacamole-guacamole-${guacamole_version}.war
    if [ $? -ne 0 ]; then
        echo "$(date "+%F %T") ${color_red}Failed to download $script_path/guacamole-guacamole-${guacamole_version}.war${color_none}"
        echo "${download_location}/binary/guacamole-guacamole-${guacamole_version}.war"
        exit
    fi

fi

# Download authentication extension
if [ ! -f $script_path/guacamole-auth-jdbc-${guacamole_version}.tar.gz ]; then

    wget -q --show-progress -O guacamole-auth-jdbc-${guacamole_version}.tar.gz ${download_location}/binary/guacamole-auth-jdbc-${guacamole_version}.tar.gz
    if [ $? -ne 0 ]; then
        echo "$(date "+%F %T") ${color_red}Failed to download $script_path/guacamole-auth-jdbc-${guacamole_version}.tar.gz${color_none}"
        echo "${download_location}/binary/guacamole-auth-jdbc-${guacamole_version}.tar.gz"
        exit
    fi

    ## Extract Guacamole files
    tar -xzf $script_path/guacamole-auth-jdbc-${guacamole_version}.tar.gz

fi

# Make directories 
mkdir -p /etc/guacamole/lib
mkdir -p /etc/guacamole/extensions

# Install guacd
$script_path/guacamole-server-${guacamole_version}

echo -e "Building Guacamole with GCC $(gcc --version | head -n1 | grep -oP '\)\K.*' | awk '{print $1}') "

echo -e "Configuring..."
$script_path/guacamole-server-${guacamole_version}/.configure --with-init-dir=/etc/init.d   
if [ $? -ne 0 ]; then
    echo -e "$(date "+%F %T") ${color_red}Failed.${color_none}"
    exit 1
else
    echo -e "OK"
fi

echo -e "Running Make. This might take a few minutes..."
$script_path/guacamole-server-${guacamole_version}/make  
if [ $? -ne 0 ]; then
    echo -e "$(date "+%F %T") ${color_red}Failed.${color_none}"
    exit 1
else
    echo -e "OK"
fi

echo -e "Running Make Install..."
$script_path/guacamole-server-${guacamole_version}/make install  
if [ $? -ne 0 ]; then
    echo -e "$(date "+%F %T") ${color_red}Failed.${color_none}"
    exit 1
else
    echo -e "OK"
fi

ldconfig
systemctl enable guacd

# Get build-folder
BUILD_FOLDER=$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)

# Move files to correct locations
mv $script_path/guacamole-${guacamole_version}.war /etc/guacamole/guacamole.war
ln -s /etc/guacamole/guacamole.war /var/lib/${TOMCAT}/webapps/
ln -s /usr/local/lib/freerdp/guac*.so /usr/lib/${BUILD_FOLDER}/freerdp/
ln -s /usr/share/java/mysql-connector-java.jar /etc/guacamole/lib/
cp $script_path/guacamole-auth-jdbc-${guacamole_version}/mysql/guacamole-auth-jdbc-mysql-${guacamole_version}.jar /etc/guacamole/extensions/

# restart tomcat
echo -e "Restarting tomcat..."

service ${TOMCAT} restart
if [ $? -ne 0 ]; then
    echo -e "$(date "+%F %T") ${color_red}Failed${color_none}"
    exit 1
else
    echo -e "OK"
fi
