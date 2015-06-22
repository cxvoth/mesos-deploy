#!/bin/bash
# Mesosphere provisioning script for private docker registry 
# and nginx secure proxy (2 docker containers managed by Marathon)
#
# Compatible with Centos 7
#
# Marathon acts as a process supervisor for docker-registry to ensure
# it is restarted if the process dies.
# This script only needs to be executed once. It will run one instance of the
# docker-registry container on a single slave managed by Marathon.
# It will also run one instance of the nginx proxy to secure the registry.
#
# Usage:
# $ secure-docker-registry <any-marathon-host>
#   $0                     $1      

# $ sudo ./secure-docker-registry.sh 192.168.99.101:8080

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No Marathon host argument supplied"
    exit 1
fi

########################################################################
##																	  ##
##								TODO								  ##
##																	  ##
########################################################################
##
##		healthchecks - https://mesosphere.github.io/marathon/docs/health-checks.html
##		run storage container once and terminate (marathon keeps attempting to restart)
##		constraints - all containers need to be on the same host
##		test - push image to private repo
##		test - pull image from private repo
##		store images in storage container?
##		docker daemon --insecure-registry (since the registry iself has no security)
##		customize registry config: -v /home/me/myfolder:/registry-conf -e DOCKER_REGISTRY_CONFIG=/registry-conf/mysuperconfig.yml
##	x	add cert to docker-registry container /etc/docker/certs.d/docker-registry.marathon.mesos:5443/ca.crt   <<< no, this is for securing the registry itself
##		add cert elsewhere? see step #6 - https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-ubuntu-14-04
##		unable to successfully launch docker with mesos native support - https://mesosphere.github.io/marathon/docs/native-docker.html
##      use HAProxy instead of nginx
##
########################################################################


# -------------------------------------------------------------------------------------------------
# Install

# Launch private docker registry, nginx proxy and docker storage container in three docker 
# colocated containers using Marthon
# 
# Any marathon instance should do; standby instances forward to master anyway
#
# MARATHON= ?? how to dynamically detect marathon master?
# MARATHON=mesos-resolve zk://192.168.99.101:2181/marathon   << WHY DOESN'T THIS WORK?
MARATHON=$1
#
# Create an empty docker storage container
# docker create --name docker-registry-proxy-config -v /etc/nginx/ssl -v /etc/nginx/conf.d busybox
#
# Populate the storage container with generated proxy credentials and SSL cert. Use the nginx container to create these since it has the tools.
# docker run --rm --volumes-from docker-registry-proxy-config quay.io/aptible/registry-proxy htpasswd -bc /etc/nginx/conf.d/docker-registry-proxy.htpasswd admin passw0rd
# docker run --rm --volumes-from docker-registry-proxy-config quay.io/aptible/registry-proxy openssl genrsa -out /etc/nginx/ssl/docker-registry-proxy.key 2048
# docker run --rm --volumes-from docker-registry-proxy-config quay.io/aptible/registry-proxy openssl req -x509 -new -nodes -key /etc/nginx/ssl/docker-registry-proxy.key -days 10000  -subj "/C=CA/ST=ON/L=Markham/O=IBM Middleware/CN=docker-registry.marathon.mesos" -out /etc/nginx/ssl/docker-registry-proxy.crt
curl -X POST -H "Content-Type: application/json" http://$MARATHON/v2/apps -d@docker-registry-proxy-config.json
#
# The registry container will not expose any ports, nor will the registry be secure.
# Store the pushed docker images outside of the docker-registry container. 
#
# DOCKER CONTAINER /registry-storage -> GUEST /vagrant/registry-storage -> HOST mydir/registry-storage 
#
# This will take some time as the docker-registry image will be downloaded from the 
# public Docker Hub repository.
# docker run --name=docker-registry 
#			 --rm=true 
#			 --expose=5000 or -P
#			 -v /vagrant/registry-storage:/registry-storage 
#            -e SETTINGS_FLAVOR=local
#   		 -e STANDALONE=true 
#  			 -e STORAGE=local 
#  			 -e STORAGE_PATH=/registry-storage 
#			 -e LOGLEVEL=debug  
#			 -e DEBUG=true 
#			registry
curl -X POST -H "Content-Type: application/json" http://$MARATHON/v2/apps -d@isolated-insecure-docker-registry.json
#
# Launch an nginx proxy with authentication and SSL enabled. Have it front all traffic
# for the docker registry
# Filenames for key, cert are from https://github.com/aptible/docker-registry-proxy/blob/master/Dockerfile
# docker run --name=docker-registry-proxy 
#			 --rm=true 
#			 --link docker-registry:registry 
#			 --volumes-from docker-registry-proxy-config
#			 -p 5443:443  
#			 quay.io/aptible/docker-registry-proxy
curl -X POST -H "Content-Type: application/json" http://$MARATHON/v2/apps -d@docker-registry-proxy.json

# -------------------------------------------------------------------------------------------------
# Verify
# 
# Verify local Docker registry is available
#
#	From the slave host running the registry docker container
#	$ docker ps -a
#	$ docker inspect docker-registry
#
#	Verify that mesos-dns has registered the app ID (app ID specifiied in secure-docker-registry.json)
# 	(may need to be inside another container)
#	$ dig docker-registry.marathon.mesos
#
#	Check the contents of the proxy configuration storage container (/etc/nginx inside docker-registry-proxy-config)
#	$ docker run -i -t --rm --volumes-from docker-registry-proxy-config centos bash
#
#   Access the private repository
#	(may need to do this within a docker container unless hosts /etc/resolv.conf has been updated to reference mesos-dns)
#
#	$ curl -k  -v https://docker-registry.marathon.mesos:5443/v1/_ping	  (no authentication required)
#
#	$ sudo docker login https://docker-registry.marathon.mesos:5443
# 		FATA[0012] Error response from daemon: v1 ping attempt failed with error: 
#		Get https://docker-registry.marathon.mesos:5443/v1/_ping: dial tcp: lookup 
#		docker-registry.marathon.mesos: no such host. If this private registry supports 
#		only HTTP or HTTPS with an unknown CA certificate, please add 
#		`--insecure-registry docker-registry.marathon.mesos:5443` to the daemon's arguments. 
#		In the case of HTTPS, if you have access to the registry's CA certificate, no need for 
#		the flag; simply place the CA certificate at 
#		/etc/docker/certs.d/docker-registry.marathon.mesos:5443/ca.crt << did this; no affect
#
#	Peer inside docker-registry:
# 	$ docker exec -ti docker-registry bash

# 	$ curl -v https://admin:passw0rd@docker-registry.marathon.mesos:5443
#
#	push an image into the private repository
#
#	query private repository - see https://docs.docker.com/reference/api/registry_api/
#		http://192.168.99.201:5000/v1/repositories/centos/7/