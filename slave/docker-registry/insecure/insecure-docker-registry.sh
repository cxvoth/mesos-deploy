#!/bin/bash
# Mesosphere provisioning script for Controller node
#  mesos-server
#  mesos authentication+authorization + mesos-credentials.json + mesos-acls.json 
#  marathon
#  marathon ssh config
#  zookeeper 
#  mesos-DNS + config.json
#  >> docker-registry (insecure) <<
#  docker-registry (insecure) slave configuration
#
# Compatible with Centos 7
#
# Marathon acts as a process supervisor for docker-registry to ensure
# it is restarted if the process dies.
# This script only needs to be executed once. It will run one instance of the
# docker-registry on a single slave managed by Marathon.
#
# Usage:
# $ insecure-docker-registry <any-marathon-host>
#   $0                       $1      

# $ sudo ./insecure-docker-registry.sh 192.168.99.101:8080

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No Marathon host argument supplied"
    exit 1
fi
if [ -z "$2" ];
  then
    echo "No ? argument supplied"
    exit 2
fi

# -------------------------------------------------------------------------------------------------
# Install

# Any marathon instance should do; standby instances forward to master anyway

# MARATHON= ?? how to dynamically detect marathon master?
# MARATHON=mesos-resolve zk://192.168.99.101:2181/marathon   << WHY DOESN'T THIS WORK?
MARATHON=$1
#
# 	{
#	  "id": "docker-registry",
#	  "cmd": "docker run -p 5000:5000 -v /vagrant/registry-storage:/registry-storage -e LOGLEVEL=debug  -e DEBUG=true -e STANDALONE=true -e STORAGE=local -e STORAGE_PATH=/registry-storage registry",
#	  "cpus": 0.5,
#	  "mem": 128.0,
#	  "instances": 1
#	}
#
# Store the pushed docker images outside of the docker-registry container. 
#
# DOCKER CONTAINER /registry-storage -> GUEST /vagrant/registry-storage -> HOST mydir/registry-storage 
#
# This will take some time as the docker-registry image will be downloaded from the 
# public Docker Hub repository.
curl -X POST -H "Content-Type: application/json" http://$MARATHON/v2/apps -d@docker-registry.json

# -------------------------------------------------------------------------------------------------
# Verify
# 
# Verify local Docker registry is available
#
#	From the slave host running the registry docker container
#	$ docker ps -a
#	$ curl localhost:5000
#
#	Verify that mesos-dns has registered the app ID (app ID specifiied in docker-registry.json)
#	$ dig docker-registry.marathon.mesos
#
#	$ curl -v -X GET http://docker-registry.marathon.mesos:5000/v1/_ping | python -m json.tool
