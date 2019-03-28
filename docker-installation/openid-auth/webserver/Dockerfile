# Use Apache Guacamole 0.9.14 from Dockerhub
FROM guacamole/guacamole:0.9.14

# Customize Apache Guacamole 0.9.14
# If you have your own or third-party extensions, you can add them to a custom GUACAMOLE_HOME directory, 
# and they will be automatically merged into the Apache Guacamole Docker image runtime configuration.

## Create a custom GUACAMOLE_HOME directory
RUN mkdir /opt/guacamole/home \
    && mkdir /opt/guacamole/home/extensions

## Set the working directory to the custom GUACAMOLE_HOME directory
WORKDIR /opt/guacamole/home

## OpenID Connect Authentication

### Add OpenID properties into guacamole.properties
ADD guacamole_home/guacamole.properties /opt/guacamole/home

### Add OpenID extension into the Apache Guacamole extensions folder
ADD guacamole_home/extensions/guacamole-auth-openid-0.9.14.jar /opt/guacamole/home/extensions

### Authentication extensions are loaded in alphabetical order 
RUN mv extensions/guacamole-auth-openid-0.9.14.jar extensions/0guacamole-auth-openid-0.9.14.jar