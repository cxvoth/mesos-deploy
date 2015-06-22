#!/bin/bash
# Mesosphere provisioning script for Slave node
#  Edit /etc/resolv.conf (include mesos-DNS IPs)
#
# Alternatively, each slave node can have their nameservers configured via DHCP
#
# Randomize order in which nameservers are used?
#
#
# Compatible with Centos 7
#
# Usage:
# $ mesos-dns-slave <dns-port> <nameserver1> <nameserver2> <nameserver3>
#   $0              $1         $2            $3            $4
# $ sudo ./mesos-dns-slave.sh 53 192.168.99.101

# Currently the DNS port is ignored since the nameserver is assumed to be running on port 53 with regards to /etc/resolv.conf

# Will be executed with sudo privledges

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No DNS port argument supplied"
    exit 1
fi

if [ -z "$2" ];
  then
    echo "No nameserver argument supplied"
    exit 2
fi

# -------------------------------------------------------------------------------------------------
# Configure

# edit resolv.conf

# nameserver nameserver1
# nameserver nameserver2
# nameserver nameserver3

# maintain original
cp /etc/resolv.conf /etc/resolv.conf.original

if [ -z "$4" ];
  then
    echo "No nameserver3 argument supplied"
  else
  	sed -i "1s/^/nameserver $4\n/g" /etc/resolv.conf
fi

if [ -z "$3" ];
  then
    echo "No nameserver2 argument supplied"
  else
  	sed -i "1s/^/nameserver $3\n/g" /etc/resolv.conf
fi

sed -i "1s/^/nameserver $2\n/g" /etc/resolv.conf

# -------------------------------------------------------------------------------------------------
# Verify

# Install dig
# sudo yum -y install bind-utils
#
# Mesos-DNS registered itself as:
#   ns1.mesos
#
# Find Mesos Master + port
# $ dig leader.mesos
# $ dig _leader._tcp.mesos SRV
# $ dig master.mesos
# $ dig _master._tcp.mesos SRV  << NO INFO
#
# $ dig <TASK-NAME>.<FRAMEWORK>.mesos
# $ dig <TASK-NAME>.marathon.mesos
# $ dig _<TASK-NAME>._tcp.marathon.mesos SRV
