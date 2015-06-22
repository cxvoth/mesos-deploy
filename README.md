# mesos-deploy

The Vagrantfile spins up one controller virtual machine and two slave machines (configurable). The controller contains ZooKeeper, mesos-master, Mesos-DNS and Marathon scheduler.

The slave virtual machines contain the mesos-slave and are configured to refer to the Mesos-DNS.

The Vagrantfile installs Mesos and accompanying software via discrete bash shell scripts.

Some of the scripts are not invoked by Vagrant's provisioning, namely setting up a private Docker registry, and securing Mesos and Marathon.

The virtual machines are all based on CentOS 7.
