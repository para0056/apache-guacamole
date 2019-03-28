# A multi-stage build of MySQL that initalizies a fresh MySQL database with the Guacamole schema

FROM guacamole/guacamole:0.9.14 as build

# Generate a SQL script which can be used to initialize a fresh MySQL database with the Guacamole schema
RUN /opt/guacamole/bin/initdb.sh --mysql > /opt/guacamole/bin/initdb.sql

FROM mysql:5.7

# Import the SQL script from the build stage into the MySQL Docker image
COPY --from=build /opt/guacamole/bin/initdb.sql /docker-entrypoint-initdb.d