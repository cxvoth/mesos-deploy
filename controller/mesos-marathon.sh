#!/bin/bash
# Mesosphere provisioning script to install Marathon framework on Controller node
#
# Compatible with Centos 7
#
# Systemd acts as a process supervisor for mesos-master and marathon to ensure
# they are restarted if the process dies.
#
# Usage:
# $ mesos-marathon <quorum> <zk-url>
#   $0             $1       $2

# $ sudo ./mesos-marathon.sh 2 zk://192.168.99.101:2181,192.168.99.102:2181,192.168.99.103:2181
# $ sudo ./mesos-marathon.sh 1 zk://192.168.99.101:2181

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No quorum argument supplied"
    exit 1
fi
if [ -z "$2" ];
  then
    echo "No zookeeper-url argument supplied"
    exit 2
fi

# -------------------------------------------------------------------------------------------------
# Install
# Add the repository for Mesos, Marathon
rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm

# Install Mesos, Marathon
# Installs both Mesos master and slave
yum -y install mesos marathon

# -------------------------------------------------------------------------------------------------
# Configure Mesos Master

# Make Mesos Masters aware of Zookeeper
MESOS_ZK_CFG='/etc/mesos/zk'
echo $2'/mesos' > $MESOS_ZK_CFG

# Set the quorum size (>50% of number of Zookeeper servers)
QUORUM_CFG='/etc/mesos-master/quorum'
echo $1 > $QUORUM_CFG

# IP address to listen on
MASTER_IP_CFG='/etc/mesos-master/ip'

# The hostname the master should advertise in ZooKeeper. 
# If left unset, the hostname is resolved from the IP address that the master binds to.
MASTER_HOSTNAME_CFG='/etc/mesos-master/hostname'

# Which IP am I?
MYIP=$(ifconfig | grep 192.168.99 | awk '{print $2}')
echo $MYIP > $MASTER_IP_CFG

# just use IP address
cp $MASTER_IP_CFG $MASTER_HOSTNAME_CFG

# -------------------------------------------------------------------------------------------------
# Start Mesos Master
#service mesos-master start  # << SysV compatible passthru to systemd
systemctl start mesos-master.service

# Systemd will restart Mesos Master process if it dies.
# see /usr/lib/systemd/system/mesos-master.service  (Restart=always)

# mesos-slave not started, but enabled (start at next boot)
# Disable mesos-slave
systemctl disable mesos-slave.service

# -------------------------------------------------------------------------------------------------
# Configure Marathon

# *** Create /etc/marathon/conf/ ***
# In this directory each command line parameter can be represented as a file
FRAMEWORK_CFG_DIR='/etc/marathon/conf'

# Create Marathon config directory
mkdir -p $FRAMEWORK_CFG_DIR

# Create hostname file
# /etc/marathon/conf/hostname
cp $MASTER_HOSTNAME_CFG $FRAMEWORK_CFG_DIR

# Create master file with contents of zk://.../mesos
# This allows Marathon to connect to Mesos
# /etc/marathon/conf/master
cp $MESOS_ZK_CFG $FRAMEWORK_CFG_DIR/master

# Make Marathon Masters aware of Zookeeper
# /etc/marathon/conf/zk
MARATHON_ZK_CFG=$FRAMEWORK_CFG_DIR'/zk'
echo $2'/marathon' > $MARATHON_ZK_CFG

# -------------------------------------------------------------------------------------------------
# Start Marathon Framework - requires mesos-master
#service marathon start # << SysV compatible passthru to systemd
systemctl start marathon.service

# Systemd will restart Marathon process if it dies.
# see /usr/lib/systemd/system/marathon.service  (Restart=always, Restart=on-abort)

# -------------------------------------------------------------------------------------------------
# Mesos console at http://<ip>:5050 
# http://<ip>:5050/master/state.json

# Marathon console at http://<ip>:8080

# These services will be automatically restarted on reboot (no need to re-execute this provisioning script).

# Verify services are running:
# 	$ systemctl status marathon.service
#   $ service marathon status

#	$ systemctl status mesos-master.service
#   $ service mesos-master status

#	$ systemctl status mesos-slave.service
#   $ service mesos-slave status


# Mesos, Mesos-DNS
# $ netstat -nlp | grep mesos

# Marathon, ZooKeeper
# $ netstat -nlp | grep java

# Using Mesos
# $ mesos help
#
# Many commands require a network reference to the master.
# It can be dynamically determined by:
# $ export MASTER=$(mesos-resolve `cat /etc/mesos/zk` 2>/dev/null)
#
#$ mesos execute --master=$MASTER --name="cluster-test" --command="sleep 40"

#  http://192.168.99.101:5050/help