#!/bin/bash
# Mesosphere provisioning script for Slave node
#
# Compatible with Centos 7
#
# Systemd acts as a process supervisor for mesos-slave to ensure
# it is restarted if the process dies.
#
# Usage:
# $ mesos-slave
#   $0            
# $ ./mesos-slave.sh <zk-url>
# $ sudo ./mesos-slave.sh zk://192.168.99.101:2181,192.168.99.102:2181,192.168.99.103:2181

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No zookeeper-url argument supplied"
    exit 1
fi


# -------------------------------------------------------------------------------------------------
# Install
# Add the repository for Mesos, Marathon
rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm

yum -y install mesos 

# -------------------------------------------------------------------------------------------------
# Mesos master is installed as well. Make sure it has not been started
#service mesos-master stop # << SysV compatible passthru to systemd
systemctl stop mesos-master.service

# Ensure Mesos Master is not automatically started on boot
systemctl disable mesos-master.service 

 # Marathon is installed as well. Make sure it has not been started
 #systemctl stop marathon.service

 # Ensure Marathon is not automatically started on boot
 #systemctl disable marathon.service

# -------------------------------------------------------------------------------------------------
# Configure
# /etc/default/mesos-slave  << sets MASTER to contents of /etc/mesos/zk
# https://docs.mesosphere.com/reference/mesos-slave/
# Make Mesos Slaves aware of Zookeeper
# Used by /etc/default/mesos-slave
MESOS_ZK_CFG='/etc/mesos/zk'
echo $1'/mesos' > $MESOS_ZK_CFG

# IP address to listen on
SLAVE_IP_CFG='/etc/mesos-slave/ip'

# Which IP am I?
MYIP=$(ifconfig | grep 192.168.99 | awk '{print $2}')
echo $MYIP > $SLAVE_IP_CFG

# The hostname the slave should report.
# If left unset, the hostname is resolved from the IP address that the slave binds to.
#SLAVE_HOSTNAME_CFG='/etc/mesos-slave/hostname'

# just use IP address
#cp $SLAVE_IP_CFG $SLAVE_HOSTNAME_CFG

# -------------------------------------------------------------------------------------------------
# Start Mesos Slave

# Systemd will restart Mesos Slave process if it dies.
# see /usr/lib/systemd/system/mesos-slave.service  (Restart=always)
systemctl enable mesos-slave.service

systemctl start mesos-slave.service




