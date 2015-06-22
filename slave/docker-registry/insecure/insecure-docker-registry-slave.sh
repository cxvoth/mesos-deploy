#!/bin/bash
# Mesosphere provisioning script for Controller node
#  mesos-server
#  mesos authentication+authorization + mesos-credentials.json + mesos-acls.json 
#  marathon
#  marathon ssh config
#  zookeeper 
#  mesos-DNS + config.json
#  docker-registry (insecure)
#  >> docker-registry (insecure) slave configuration <<
#
# Compatible with Centos 7
#
# This script must be run on all slaves. It will configure docker to
# first check the insecure docker-registry before checking the public Docker Hub.
# Assumes:
#   mesos-DNS
#   docker-registry container id is "docker-registry"
#	docker registry using port 5000
#
# Usage:
# $ insecure-docker-registry-slave 
#   $0                      

# $ sudo ./insecure-docker-registry-slave.sh 

# Will be executed with sudo privledges

# Edit /etc/sysconfig/docker
# Add to beginning of file
#   INSECURE_REGISTRY='--insecure-registry docker-registry.marathon.mesos:5000'
#	ADD_REGISTRY='--add-registry docker-registry.marathon.mesos'
sed -i "1s/^/INSECURE_REGISTRY='--insecure-registry docker-registry.marathon.mesos:5000'\n/g" /etc/sysconfig/docker
sed -i "1s/^/ADD_REGISTRY='--add-registry docker-registry.marathon.mesos'\n/g" /etc/sysconfig/docker
	
# see https://access.redhat.com/articles/1354823

systemctl restart docker