#!/bin/bash
# Mesosphere provisioning script for Controller node
#  mesos-server 
#  mesos authentication+authorization + mesos-credentials.json + mesos-acls.json 
#  marathon 
#  >> marathon ssh config <<
#  zookeeper 
#  mesos-DNS + config.json
#
# Compatible with Centos 7
#
# Enables SSL for Marathon on port :4443 (self-signed certificate)
# Configures basic-auth for Maraton web UI access.
# Unable to disable http access. 
# Set credentials used by Marathon framework to authenticate with Mesos-Master
#
# Usage:
# $ marathon-secure 
#   $0             

# $ sudo ./marathon-secure.sh

# Will be executed with sudo privledges
FRAMEWORK_CFG_DIR='/etc/marathon/conf'

# *** Set framework name ***
# --framework_name marathon
# Note: must match acls.json
echo 'marathon' > $FRAMEWORK_CFG_DIR/framework_name

# ***************************************************
# ******** Enable Web UI password protection ********
# ***************************************************

# Env var not effective - set in /etc/marathon/conf instead
#MESOSPHERE_HTTP_CREDENTIALS=marathon-ops:password
# --http_credentials username:password
echo 'marathon-ops:password' > $FRAMEWORK_CFG_DIR/http_credentials

# Default realm for credentials seems to be NULL (should be Mesosphere)
# --http_realm Mesosphere 
# Cannot be set via /etc/marathon/conf/http_realm; Marathon will not start.
#echo 'Marathon' > $FRAMEWORK_CFG_DIR/http_realm

# ***************************************************
# *************** Configure SSL Only ****************
# ***************************************************
# --disable_http
# Cannot be set via /etc/marathon/conf/disable_http (file can be empty, 1, true); Marathon will not start.

# --http_port 8088
# Cannot be set via /etc/marathon/conf/http_port; Marathon will not start.
#echo '8088' > $FRAMEWORK_CFG_DIR/http_port

# --https_port 4443
echo '4443' > $FRAMEWORK_CFG_DIR/https_port

# Create self signed certificate
rm -f /etc/marathon/marathon_keystore.jks
keytool -genkeypair -alias marathon -keystore /etc/marathon/marathon_keystore.jks -storepass password -keypass password -validity 3650 -dname "cn=Marathon Framework, ou=IBM Middleware, o=IBM, c=CA"

# These env vars don't work - set in /etc/marathon/conf instead
# Alternatively tried to set service env vars in their own file /etc/marathon/marathon-service-env
# Modify /usr/lib/systemd/system/marathon.service to add:
# EnvironmentFile=-/etc/marathon/marathon-service-env
# This didn't work either.

#MESOSPHERE_KEYSTORE_PATH=/etc/marathon/marathon_keystore.jks
#MESOSPHERE_KEYSTORE_PASS=password

echo '/etc/marathon/marathon_keystore.jks' > $FRAMEWORK_CFG_DIR/ssl_keystore_path

echo 'password' > $FRAMEWORK_CFG_DIR/ssl_keystore_password

# ***************************************************
# ************ Set Framework Credentials ************
# ***************************************************
#
# Note: These credentials MUST be removed even if mesos-master --authenticate=false otherwise Marathon framework cannot connect to Mesos
#
# --mesos_authentication_principal <username>  (username must exist in mesos-master --credentials json)
# tried with and without newline (echo/echo -n)
#echo -n 'user1' > $FRAMEWORK_CFG_DIR/mesos_authentication_principal

# --mesos_authentication_secret_file <password-filename>
# tried with and without newline (echo/echo -n)
#echo -n 'password' > /etc/marathon/framework-password
# tried with and without newline (echo/echo -n)
#echo '/etc/marathon/framework-password' > $FRAMEWORK_CFG_DIR/mesos_authentication_secret_file

# ***************************************************
# ********* Set Framework ACL Role and User *********
# ***************************************************
# Role and user must be referenced in acls.json
#echo 'dev' > $FRAMEWORK_CFG_DIR/mesos_role
# echo 'root' > FRAMEWORK_CFG_DIR/mesos_user

# -------------------------------------------------------------------------------------------------
# Start Marathon Framework - requires mesos-master
#service marathon start # << SysV compatible passthru to systemd
systemctl restart marathon.service

