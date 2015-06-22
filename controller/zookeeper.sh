#!/bin/bash
# Mesosphere provisioning script for installing ZooKeeper to Controller node
#
# Compatible with Centos 7
#
# Usage:
# $ zookeeper <zookeeper-id> <ip-1> <ip-2> <ip-3>
#   $0            $1             $2     $3     $4

# $ sudo ./zookeeper.sh 1 192.168.99.101 192.168.99.102 192.168.99.103

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No zookeeper-id argument supplied"
    exit 1
fi

if [ -z "$2" ];
  then
    echo "No controller1-IP argument supplied"
    exit 2
fi

# -------------------------------------------------------------------------------------------------
# Add the repository for Zookeeper
#rpm -Uvh http://archive.cloudera.com/cdh4/one-click-install/redhat/6/x86_64/cloudera-cdh-4-0.x86_64.rpm  # Centos 6
rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm

# Install and initialize Zookeeper
#yum -y install zookeeper   # Centos 6
#yum -y install zookeeper-server  # Centos 6
yum -y install mesosphere-zookeeper


# Creates /var/lib/zookeeper/myid
#service zookeeper-server init --myid=$1     # Centos 6
echo $1 > /var/lib/zookeeper/myid

# Zookeeper config: /etc/zookeeper/conf/zoo.cfg
ZK_CFG=/etc/zookeeper/conf/zoo.cfg

# Inform Zookeeper of other ZK hosts
echo 'server.1='$2':2888:3888' >> $ZK_CFG

if [ -z "$3" ];
  then
    echo "No controller2-IP argument supplied"
  else
  	echo 'server.2='$3':2888:3888' >> $ZK_CFG
fi

if [ -z "$4" ];
  then
    echo "No controller3-IP argument supplied"
  else
  	echo 'server.3='$4':2888:3888' >> $ZK_CFG
fi

unset ZK_CFG

# Start Zookeeper 

#/lib/zookeeper/bin/zkServer start
systemctl start zookeeper.service


# Zookeeper is setup as a SysV service (rc.d) and will automatatically start upon boot
# $ chkconfig
# $ chkconfig zookeeper-server on (equivalent to systemd  "service zookeeper-server disable", "systemctl disable zookeeper-server.service")
#
# Zookeeper is not listed as a systemd service
# $ systemctl list-unit-files


# Keep Zookeeper runnning using a supervisory process
# Convert from SysV to Systemd: https://issues.apache.org/jira/browse/ZOOKEEPER-2095

# To verify Zookeeper (all instances specified in zoo.cfg must be running):
#   $ /opt/mesosphere/zookeeper/bin/zkCli.sh -server 127.0.0.1:2181

#  	$ zookeeper-client -server 127.0.0.1:2181
#	[zk:...] ls /
#   [zk:...] quit

