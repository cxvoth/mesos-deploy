#!/bin/bash
# Mesosphere provisioning script for installing Mesos-DNS to Controller node
#
# Compatible with Centos 7
#
# Systemd acts as a process supervisor for mesos-DNS to ensure
# it is restarted if the process dies.
#
# Usage:
# $ mesos-dns <dns-port> <zk-url> <nameserver1> <nameserver2> 
#   $0        $1         $2       $3            $4      

# $ sudo ./mesos-dns.sh 53 zk://1.2.3.4:2181,5.6.7.8:2181,9.10.11.12:2181 8.8.8.8 208.67.222.222
# $ sudo ./mesos-dns.sh 53 zk://192.168.99.101:2181 9.26.33.5 9.26.32.5
#
# Where nameserver1 and nameserver2 are public DNS IPs (Google, OpenDNS), or internal DNS servers (but not cluster DNS servers)

# Will be executed with sudo privledges

# The following files are required:
# ./controller/dns/mesos-dns.service
# ./controller/dns/mesos-dns-config.json
cd /vagrant/controller/dns

# Check for required parameters
if [ -z "$1" ];
  then
    echo "No DNS port argument supplied"
    exit 1
fi
if [ -z "$2" ];
  then
    echo "No zookeeper-url argument supplied"
    exit 2
fi
if [ -z "$3" ];
  then
    echo "No nameserver1 argument supplied"
    exit 3
fi
if [ -z "$4" ];
  then
    echo "No nameserver2 argument supplied"
    exit 4
fi

# -------------------------------------------------------------------------------------------------
# Install

# Go runtime needed to run Mesos-DNS
# Download Go 
echo "Downloading Go..."
wget -O /usr/tmp/go.tar.gz https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz

tar -C /usr/local -xzf /usr/tmp/go.tar.gz

# /usr/local/go is the standard location
# GOROOT only needs to be set if the location is custom
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin

# You must set the GOPATH environment variable to point to the directory where outside go packages will be installed.
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Git needed to install Mesos-DNS
yum -y install git

# Download Godep
echo "Downloading Godep..."
go get github.com/tools/godep

# Download Mesos DNS
# $HOME/go/bin/mesos-dns
echo "Downloading Mesos-DNS..."
go get github.com/mesosphere/mesos-dns

# Create mesos-dns binary
cd $GOPATH/src/github.com/mesosphere/mesos-dns
make all

echo "Adding Mesos-DNS Service..."
cp mesos-dns.service /usr/lib/systemd/system/

# -------------------------------------------------------------------------------------------------
# Configure Mesos DNS

DNS_CFG=/etc/mesos-dns/config.json

mkdir /etc/mesos-dns
cp mesos-dns-config.json $DNS_CFG

cp $GOPATH/src/github.com/mesosphere/mesos-dns/mesos-dns /usr/bin

# Substitute PORT in /etc/mesos-dns/config.json
# Substitute NAMESERVER in /etc/mesos-dns/config.json
# Substitute ZKURL with "zk:// .. /mesos" in /etc/mesos-dns/config.json

sed -i "s/PORT/$1/g" $DNS_CFG

# Escape sed special characters like /
# zk://192.168.99.101:2181 -> zk:\/\/192.168.99.101:2181
ZKURL=$(echo $2 | sed -e 's/[\/&]/\\&/g')

# Replace 'ZKURL' with '$ZKURL/mesos'
sed -i "s/ZKURL/$ZKURL\/mesos/g" $DNS_CFG

# '1.1.1.1','2.2.2.2'
#NAMESERVERS="'$3','$4'"
# "1.1.1.1","2.2.2.2"
#NAMESERVERS=$(echo $NAMESERVERS | sed "s/'/\"/g")

NAMESERVERS=\"$3\",\"$4\"

# Replace 'NAMESERVERS' with '$3,$4' 
sed -i "s/NAMESERVERS/$NAMESERVERS/g" $DNS_CFG

# Note: "masters" should not need to be set because "zk" is supplied

# -------------------------------------------------------------------------------------------------
# Execute
# $GOPATH/bin is on path
# /root/go/bin/mesos-dns
# Copied to /usr/bin

# Execute standalone (no supervisor, no start on boot)
#mesos-dns -config=$DNS_CFG & 

# Ensure Mesos-DNS is startup on boot
systemctl enable mesos-dns.service

# Execute as Systemd service
systemctl start mesos-dns.service

# Execute as Marathon workload
# see https://www.digitalocean.com/community/tutorials/how-to-configure-a-production-ready-mesosphere-cluster-on-ubuntu-14-04


# -------------------------------------------------------------------------------------------------
# Verify
# $ curl http://localhost:8123/v1/config
#
# Launch a task in Marathon with name <task-name>
#  use command: python -m SimpleHTTPServer 
#
# $ curl http://localhost:8123/v1/hosts/<task-name>.marathon.mesos
# $ curl http://localhost:8123/v1/services/_<task-name>._tcp.marathon.mesos



