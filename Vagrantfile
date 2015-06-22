# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

    box_name = "chef/centos-7.0"

    # Note: If you change the IPs, also modify the shell scripts
    controllers = {

        'controller1' => {
            :name => 'controller1',  # hostname will be controller1.vagrant
            :ip => '192.168.99.101',
            :box => box_name,
            :zkid => 1
#            :forwarded_port_guest => 811,
#            :forwarded_port_host => 8811
        }
=begin        
        ,
        'controller2' => {
            :name => 'controller2',
            :ip => '192.168.99.102',
            :box => box_name,
            :zkid => 2
#            :forwarded_port_guest => 821,
#            :forwarded_port_host => 8821
        },

        'controller3' => {
            :name => 'controller3',
            :ip => '192.168.99.103',
            :box => box_name,
            :zkid => 3
#            :forwarded_port_guest => 899,
#            :forwarded_port_host => 8899
        }
=end

    }

    slaves = {
        'slave1' => {
            :name => 'slave1', # hostname will be slave1.vagrant
            :ip => '192.168.99.201',
            :box => box_name
        },
        'slave2' => {
            :name => 'slave2', 
            :ip => '192.168.99.202',
            :box => box_name
        }
    }

# External DNS Servers (maximum of 2)
dnsServers = ["8.8.8.8","208.67.222.222"] # Google, OpenDNS
#dnsServers = ["9.26.33.5", "9.26.32.5"] # torolab

# Internal DNS Port (internal DNS servers are the first three controller IPs)
dnsPort = 53

# Collect all controller IPs
ips = Array.new
controllers.each do |key,value|
    ips.push(value[:ip])
end

# Collect all Zookeeper IPs + Zookeeper port
zks = Array.new
ips.each do | ip |
    zks.push(ip + ":2181")
end

=begin
# Collect all Mesos Master IPs + master port
mstrs = Array.new
ips.each do | ip |
    mstrs.push(ip + ":5050")
end

quotedMstrs = Array.new
mstrs.each do | m |
  quotedMstrs.push("\""+m+"\"")
end
=end

#  "zk://IP1:2181,IP2:2181,IP3:2181"
zkUrl = "zk://"+zks.join(",")

# Quorum is >50% of all controller nodes (2 for 3, 3 for 5, 4 for 7, etc)
quorum = (controllers.length/2.to_f).ceil
#puts "Quorum= #{quorum}"
#puts zkUrl

controllers.each do |key,value|

    boxname = value[:name]
    config.vm.provision :shell, inline: "echo *** Processing box: #{value[:name]} ***"

    config.vm.define boxname do |app_config|

        app_config.vm.box = value[:box]
        app_config.vm.host_name = "%s.vagrant" % value[:name]

        app_config.vm.provider "virtualbox" do |vb|
          # Display the VirtualBox GUI when booting the machine
          vb.gui = false
          vb.name = "#{value[:name]}"
 
          # Customize the amount of memory on the VM:
          vb.memory = 1024
          vb.cpus = 1
          vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
        end

        app_config.vm.network "private_network", ip: value[:ip]
#        app_config.vm.network "forwarded_port", guest: value[:forwarded_port_guest], host: value[:forwarded_port_host]

#        app_config.ssh.forward_agent = true

 #       provision_filename = key.to_s + "-provision.sh"
 #       app_config.vm.provision "shell", inline: "echo #{provision_filename}"

        app_config.vm.provision "shell", inline: "echo *** Provisioning Zookeeper to #{value[:name]}... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          s.path = "controller/zookeeper.sh"
          # execute script with sudo
          s.privileged = true

 #         s.args = "#{value[:zkid]} 192.168.99.101 192.168.99.102 192.168.99.103"
           s.args = "#{value[:zkid]} "+ips.join(" ")

           puts s.path+" "+s.args
        end


        app_config.vm.provision "shell", inline: "echo *** Provisioning Mesos and Marathon to #{value[:name]}... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          s.path = "controller/mesos-marathon.sh"
          # execute script with sudo
          s.privileged = true

 #         s.args = "2 zk://192.168.99.101:2181,192.168.99.102:2181,192.168.99.103:2181"
 #         s.args = "1 zk://192.168.99.101:2181"
          s.args = "#{quorum} "+zkUrl

          puts s.path+" "+s.args
        end

        app_config.vm.provision "shell", inline: "echo *** Provisioning Mesos DNS to #{value[:name]}... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          # mesos-dns <dns-port> <zk-url> <nameserver1> <nameserver2> 
          s.path = "controller/dns/mesos-dns.sh"
          # execute script with sudo
          s.privileged = true

 #         s.args = "8053 zk://192.168.99.101:2181,192.168.99.102:2181,192.168.99.103:2181 9.26.33.5 9.26.32.5        \"192.168.99.101:5050\",\"192.168.99.102:5050\""
 #         s.args = "8053 zk://192.168.99.101:2181"
          s.args = "#{dnsPort} "+zkUrl+" "+dnsServers.join(" ") #+" "+quotedMstrs.join(",")

          puts s.path+" "+s.args
        end

        # SECURE MESOS - require framework authentication
        # SECURE MARATHON - require user authentication  


        # Start mesos-slave on Controller nodes
        # SET SPECIAL ATTRIBUTES ON THIS SLAVE TO DENOTE THAT IT IS RUNNING ON CONTROLLER NODE
#        app_config.vm.provision "shell", inline: "sudo service mesos-slave start"

        # provisioning
#        if File.exists?(File.join(vagrant_dir,'provision',boxname + "-provision.sh")) then
#            app_config.vm.provision "shell", inline: "echo +++exists+++"
#            app_config.vm.provision :shell, :path => File.join( "provision", boxname + "-provision.sh" )
#        else
#            app_config.vm.provision "shell", inline: "echo PROVISION FILE DOES NOT EXIST!"
#        end

        # Shared NFS folder
        # app_config.vm.synced_folder "shared/nfs/", "/vagrant/", type: "nfs"
#        app_config.vm.synced_folder "shared/nfs/", "/vagrant/"

    end # config.vm.define opts[:name] do |config|

  end # controllers.each


  slaves.each do |key,value|

    boxname = value[:name]
    config.vm.provision :shell, inline: 'echo boxname: ' + boxname

    config.vm.define boxname do |app_config|

        app_config.vm.box = value[:box]
        app_config.vm.host_name = "%s.vagrant" % value[:name]

        app_config.vm.provider "virtualbox" do |vb|
          # Display the VirtualBox GUI when booting the machine
          vb.gui = false
          vb.name = "#{value[:name]}"
 
          # Customize the amount of memory on the VM:
          vb.memory = 512
          vb.cpus = 1
          vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
        end

        app_config.vm.network "private_network", ip: value[:ip]

        app_config.vm.provision "shell", inline: "echo *** Provisioning Mesos Slave to #{value[:name]}... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          s.path = "slave/mesos-slave.sh"
          s.args = zkUrl
          # execute script with sudo
          s.privileged = true

 #         puts s.path+" "+s.args
        end

        app_config.vm.provision "shell", inline: "echo *** Configuring Mesos Slave #{value[:name]} to use Mesos-DNS... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          # $ mesos-dns-slave <dns-port> <nameserver1> <nameserver2> <nameserver3>
          s.path = "slave/dns/mesos-dns-slave.sh"
          # execute script with sudo
          s.privileged = true

#         s.args = "8053 192.168.99.101 192.168.99.102 192.168.99.103"
          s.args = "#{dnsPort} "+ips.join(" ")

          puts s.path+" "+s.args
        end

        app_config.vm.provision "shell", inline: "echo *** Installing Docker and Configuring Mesos Slave #{value[:name]} to use Docker... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          s.path = "slave/docker/docker-slave.sh"
          # execute script with sudo
          s.privileged = true
        end

        app_config.vm.provision "shell", inline: "echo *** Configuring Docker #{value[:name]} to use DNS... ***"
        app_config.vm.provision "shell" do |s|
          # path is relative to Vagrantfile
          s.path = "slave/dns/docker-slave-dns.sh"
          s.args = ips.join(",")
          # execute script with sudo
          s.privileged = true
        end

    end # config.vm.define opts[:name] do |config|

  end # slaves.each

end
