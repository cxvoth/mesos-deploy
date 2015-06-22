#!/bin/bash
# Mesosphere provisioning script for Controller node
#  mesos-server 
#  >> mesos authentication+authorization + mesos-credentials.json + mesos-acls.json <<
#  marathon 
#  marathon ssh config
#  zookeeper 
#  mesos-DNS + config.json
#
# Compatible with Centos 7
#
# Enables Framework authentication
# Sets credential repository used for framework+slave authentication
# Sets access control list (ACLs) for user/framework, role and action
#
# Usage:
# $ mesos-secure 
#   $0             

# $ sudo ./mesos-secure.sh

# Will be executed with sudo privledges

MESOS_CFG_DIR='/etc/mesos-master'

# *** Only allow authenticated frameworks to register with Mesos ***

#yum -y install cyrus-sasl-gssapi
#yum -y install cyrus-sasl-devel cyrus-sasl-md

# Cannot get Framework authentication to work!
# I0519 04:16:31.462635 21387 master.cpp:3818] Authenticating scheduler-d1f0dba9-6073-4c1f-8add-133cc11d786b@127.0.0.1:49897
# I0519 04:16:31.462877 21387 master.cpp:3829] Using default CRAM-MD5 authenticator
# I0519 04:16:31.464602 21387 authenticator.hpp:170] Creating new server SASL connection
# W0519 04:16:31.466275 21387 authenticator.hpp:213] Failed to get list of mechanisms: no mechanism available
# W0519 04:16:31.467200 21387 master.cpp:3871] Failed to authenticate scheduler-d1f0dba9-6073-4c1f-8add-133cc11d786b@127.0.0.1:49897: Failed to get list of mechanisms: SASL(-4): no mechanism available: Internal Error -4 in server.c near line 1757

# --authenticate true
# Note: Setting authenticate to false or removing altogether is not enough to disable framework authentication!
# --mesos_authentication_principal and --mesos_authentication_secret_file must be disabled/removed from the Marathon framework initialization.
#echo 'true' > $MESOS_CFG_DIR/authenticate

# --authenticators crammd5
# tried with and without newline (echo/echo -n)
#echo 'crammd5' > $MESOS_CFG_DIR/authenticators

# --credentials /etc/mesos-credentials.json
# tried as 'username password' file (newline delimited)
# tried file:///etc/mesos-credentials.passwd format
#cp mesos-credentials.json /etc/
#echo '/etc/mesos-credentials.json' > $MESOS_CFG_DIR/credentials

#echo 'user1 password' > /etc/mesos-credentials.passwd
#echo '/etc/mesos-credentials.passwd' > $MESOS_CFG_DIR/credentials

#cp mesos-acls.json /etc/
#echo '/etc/mesos-acls.json' > $MESOS_CFG_DIR/acls

# -------------------------------------------------------------------------------------------------
# Start Mesos Master 
#service mesos-master start # << SysV compatible passthru to systemd
systemctl restart mesos-master.service

