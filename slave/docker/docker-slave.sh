#!/bin/bash
# Mesosphere provisioning script for installing and configuring docker on Slave node
#
# Compatible with Centos 7
#
# Systemd acts as a process supervisor for docker daemon to ensure
# it is restarted if the process dies.
#
#
# Usage:
# $ docker-slave
#   $0            
# $ sudo ./docker-slave.sh

# Will be executed with sudo privledges

# -------------------------------------------------------------------------------------------------
# Install

yum -y install docker
yum -y install device-mapper-event-libs

# CentOS-7 introduced firewalld, which is a wrapper around iptables and can conflict with Docker.
# When firewalld is started or restarted it will remove the DOCKER chain from iptables, preventing Docker from working properly.
# When using Systemd, firewalld is started before Docker, but if you start or restart firewalld after Docker, you will have to restart the Docker daemon.
#
# Docker daemon must be started AFTER firewalld

# -------------------------------------------------------------------------------------------------
# Configure

# Ensure Docker daeom starts on boot
#chkconfig docker on
systemctl enable docker.service

# Update slave configuration to specify the use of the Docker containerizer
# Order denotes priority
echo 'docker,mesos' > /etc/mesos-slave/containerizers

# Increase the executor timeout to account for the potential delay in pulling a docker image to the slave.
echo '5mins' > /etc/mesos-slave/executor_registration_timeout

# Marathon --task_launch_timeout deprecated

# Force reload of Slave configuration
systemctl reload-or-restart mesos-slave.service

# -------------------------------------------------------------------------------------------------
# Start Docker daemon
 systemctl start docker.service

# Verify
 # $ sudo docker pull centos
 # $ sudo docker images centos
 # $ sudo docker run -i -t centos /bin/bash