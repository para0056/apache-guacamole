#!/bin/bash

# Verify the script is being called from entrypoint.sh
if [ -z "$guacamole_version" ] || [ -z "$guacamole_location" ] || [ -z "$script_path" ]; then
    echo "$(date "+%F %T") mysql-connect must be called via entrypoint.sh."
    exit 1
fi

# Read script arguments
while [ "$1" != "" ]; do
    case $1 in
        --help )                help
                                ;;
        --mysql-hostname )      shift 
                                mysql_hostname="$1"
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

# Check for empty positional parameters
if [ -z "$mysql_hostname" ] || [ -z "$mysql_db_name" ] || [ -z "$mysql_db_user" ] || [ -z "$mysql_db_user_pwd" ]; then
    echo "$(date "+%F %T") --mysql-hostname and/or --mysql-db-name and/or --mysql-db-user and/or --mysql-db-user-pwd."
    exit 1
fi

# Download jdbc authentication extension
if [ ! -f guacamole-auth-jdbc-${guacamole_version}.tar.gz ]; then
  wget -q --show-progress -O guacamole-auth-jdbc-${guacamole_version}.tar.gz ${guacamole_location}/binary/guacamole-auth-jdbc-${guacamole_version}.tar.gz
fi 

# Apply database schema
sudo apt-get install mysql-client -y

## Check if database schema is empty
db_table=guacamole_user
sql=$(printf 'SHOW TABLES LIKE "%s"' "$db_table")
  
if [[ $(mysql -h "$mysql_hostname" -P 3306 -u "$mysql_db_user" -p"$mysql_db_user_pwd" -e "$sql" "$mysql_db_name") ]]; then
    echo "Database schema not empty... skipping schema"
else
    echo "Database schema empty... applying schema"

    ## Extract database schema
    tar -xzf guacamole-auth-jdbc-${guacamole_version}.tar.gz

    ## Apply database schema
    cat guacamole-auth-jdbc-${guacamole_version}/mysql/schema/*.sql | mysql -h "$mysql_hostname" -P 3306 -u "$mysql_db_user" -p"$mysql_db_user_pwd" "$mysql_db_name"
fi

# Apply database configuration to Apache Guacamole
mkdir -p /etc/guacamole
echo "mysql-hostname: ${mysql_hostname}" >> /etc/guacamole/guacamole.properties
echo "mysql-port: 3306" >> /etc/guacamole/guacamole.properties
echo "mysql-database: ${mysql_db_name}" >> /etc/guacamole/guacamole.properties
echo "mysql-username: ${mysql_db_user}" >> /etc/guacamole/guacamole.properties
echo "mysql-password: ${mysql_db_user_pwd}" >> /etc/guacamole/guacamole.properties
