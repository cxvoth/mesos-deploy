#!/bin/bash
# Mesosphere provisioning script for Slave node - private registry
#  mesos-slave
#  docker
#  docker container's /etc/resolve.conf (include mesos-DNS IPs)
#
# Compatible with Centos 7
#
# Usage:
# $ docker-slave-registry hostname
#   $0                    $1
# $ sudo ./docker-slave-registry.sh docker-registry.marathon.mesos

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No private docker registry hostname argument supplied"
    exit 1
fi

# -------------------------------------------------------------------------------------------------
# Install

# -------------------------------------------------------------------------------------------------
# Configure

# Create docker config file used by docker systemd service /usr/lib/systemd/system/docker.service
# /etc/sysconfig/docker

echo "ADD_REGISTRY='--add-registry $1'" >> /etc/sysconfig/docker

# -------------------------------------------------------------------------------------------------
# Force reload of docker configuration
 systemctl reload-or-restart docker.service

# Verify
 # $ curl http://docker-registry.marathon.mesos:5000/v1/search | python -m json.tool