#!/bin/bash
# Mesosphere provisioning script for configuring docker to use mesos-dns on Slave node 
#
# Compatible with Centos 7
#
#
# Usage:
# $ docker-slave-dns ip1,ip2,ip3
#   $0               $1
# $ sudo ./docker-slave-dns.sh 192.168.99.101,192.168.99.102

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No nameserver IP(s) supplied. Up to three can be specified IP1,IP2,IP3"
    exit 1
fi

# -------------------------------------------------------------------------------------------------
# Install

# -------------------------------------------------------------------------------------------------
# Configure

# Create docker config file used by docker systemd service /usr/lib/systemd/system/docker.service
# /etc/sysconfig/docker-network

# dns and dns-search will modify containers /etc/resolv.conf
echo "DOCKER_NETWORK_OPTIONS='--dns=$1 --dns-search=marathon.mesos'" > /etc/sysconfig/docker-network

# -------------------------------------------------------------------------------------------------
# Force reload of docker configuration
 systemctl reload-or-restart docker.service

# Verify
 # $ sudo docker pull centos
 # $ sudo docker images centos
 # $ sudo docker run -i -t centos /bin/bash
 #    verify contents of /etc/resolv.conf inside container