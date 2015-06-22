# mesos-deploy

This project contains everything needed to create controller nodes and slave nodes for Mesos+Marathon

The Vagrantfile spins up one controller virtual machine and two slave machines (configurable). The controller contains ZooKeeper, mesos-master, Mesos-DNS and Marathon scheduler.

The slave virtual machines contain the mesos-slave and are configured to refer to the Mesos-DNS.

The Vagrantfile installs Mesos and accompanying software via discrete bash shell scripts.

Some of the scripts are not invoked by Vagrant's provisioning, namely setting up a private Docker registry, and securing Mesos and Marathon.

The virtual machines are all based on CentOS 7.

Controller Node (x3)
	known IP (for zookeeper, dns)
	zookeeper (+ jre)	
	mesos-server (+ perl, svn)
	marathon  
	mesos-DNS (+ go, git)

Worker Node (xN)
	/etc/resolve.conf (include mesos-DNS IPs)
	mesos-slave (docker containerizer enabled)
	docker
	dig (optional; for testing DNS)

Worker Node container (x1)
	docker-registry

---------------------------------------------------------------------------------------------------------
Building a single controller node from scratch:
Use a base box "chef/centos-7.0"

sudo ./zookeeper.sh 1 192.168.99.101
sudo ./mesos-marathon.sh 1 zk://192.168.99.101:2181
sudo ./mesos-secure.sh
sudo ./marathon-secure.sh
sudo ./mesos-dns.sh 53 zk://192.168.99.101:2181 9.26.33.5 9.26.32.5   (uses mesos-dns-config.json, mesos-dns.service)

Building a slave node from scratch (set VM up with a different IP!):
Use a base box "chef/centos-7.0"

sudo ./mesos-slave.sh zk://192.168.99.101:2181
sudo ./mesos-dns-slave.sh 53 192.168.99.101     << (OPT) this will configure the slave nodes /etc/resolv.conf
sudo ./docker-slave.sh
sudo ./docker-slave-dns.sh 192.168.99.101		<< this will configure all container's /etc/resolv.conf
sudo ./docker-slave-registry.sh docker-registry.marathon.mesos

sudo ./secure-docker-registry.sh 192.168.99.101:8080	<< uses secure-docker-registry.json

Testing:

On the Controller:
	see https://github.com/mesosphere/marathon/tree/master/examples

	__Mesos-Master__

	Open browser to: http://controller1:5050

	MASTER=$(mesos-resolve `cat /etc/mesos/zk`)
	mesos-execute --master=$MASTER --name="cluster-test" --command="sleep 5"

	/usr/local/mesos-0.20.1/build/src/examples/java/test-framework 192.168.99.101:5050

	__Zookeeper__
	/opt/mesosphere/zookeeper/bin/zkCli.sh -server 127.0.0.1:2181

	__Mesos-DNS__
	curl http://localhost:8123/v1/config
	curl http://localhost:8123/v1/hosts/<task-name>.marathon.mesos
	curl http://localhost:8123/v1/services/_<task-name>._tcp.marathon.mesos

	On the Slave, install dig
	sudo yum -y install bind-utils

	Find Mesos Master + port
	dig leader.mesos
	dig _leader._tcp.mesos SRV
	dig master.mesos
	dig _master._tcp.mesos SRV  << NO INFO

	dig <TASK-NAME>.<FRAMEWORK>.mesos
	dig <TASK-NAME>.marathon.mesos
	dig _<TASK-NAME>._tcp.marathon.mesos SRV

	__Marathon__

	Open browser to: http://controller1:8080

	job.json:
	{
    "id": "hello",
    "cmd": "env && sleep 60",
    "mem": 16,
    "cpus": 0.1,
    "instances": 1,
    "disk": 0.0,
    "ports": [0]
	}

	curl -i -H 'Content-Type: application/json' -d@job.json 192.168.99.101:8080/v2/apps

	__Docker__

	sudo docker run -i -t centos /bin/bash
	sudo docker ps

	job.json:
	{
    "id": "inky", 
    "container": {
        "docker": {
            "image": "mesosphere/inky"
        },
        "type": "DOCKER",
        "volumes": []
    },
    "args": ["hello"],
    "cpus": 0.2,
    "mem": 32.0,
    "instances": 1
	}

	curl -i -H 'Content-Type: application/json' -d@job.json 192.168.99.101:8080/v2/apps

	job.json:
	{
	  "id": "bridged-webapp",
	  "cmd": "python3 -m http.server 8080",
	  "cpus": 0.5,
	  "mem": 64.0,
	  "instances": 2,
	  "container": {
	    "type": "DOCKER",
	    "docker": {
	      "image": "python:3",
	      "network": "BRIDGE",
	      "portMappings": [
	        { "containerPort": 8080, "hostPort": 0, "servicePort": 9000, "protocol": "tcp" },
	        { "containerPort": 161, "hostPort": 0, "protocol": "udp"}
	      ]
	    }
  	  },
  	  "healthChecks": [
    	{
	      "protocol": "HTTP",
	      "portIndex": 0,
	      "path": "/",
	      "gracePeriodSeconds": 5,
	      "intervalSeconds": 20,
	      "maxConsecutiveFailures": 3
	    }
  	  ]
	}


To upgrade from a single controller node to multiple (3,7,etc):

On the Controller:
	ZooKeeper -> Update /var/lib/zookeeper/myid to be a unique integer for each node
	ZooKeeper -> Update /etc/zookeeper/conf/zoo.cfg to include a reference to each zookeeper node (using myid numbers)
	Mesos Master -> Update /etc/mesos/zk to include all Zookeeper servers (/mesos namespace)
	Mesos Master -> Update /etc/mesos-master/quorum from 1 to >50% of master servers (so for 3 servers, quorum is 2)
	Marathon -> Update /etc/marathon/conf/master to include all Zookeeper servers (same as /etc/mesos/zk) (this should not be required since /etc/marathon/conf/zk is used)
	Marathon -> Update /etc/marathon/conf/zk to include all Zookeeper servers (/marathon namespace)
	Mesos-DNS -> Update "zk" and "masters" keys in /etc/mesos-dns/config.json (masters should not be required since zk is used)

On the Slave:
	Mesos-Slave -> Update /etc/mesos/zk to include all Zookeeper servers (/mesos namespace)

