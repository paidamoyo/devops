# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant plug-ins in use:
#  vagrant-vbguest to ensure all VirtualBox VMs have guest additions
#  vagrant-hostmanager to manipulate /etc/hosts on the guest VMs and host machine.
#  vagrant-proxyconf to configure an HTTP proxy for apt [requires instructor VM to be booted on an accessible IP]
#
# If vagrant-hostmanager isn't installed edit /etc/hosts on your laptop and place these entries in it.
# 172.16.1.10 web
# 172.16.1.11 db
# 172.16.1.2 monitor
# 172.16.1.3 go
#
# If you're running in AWS or other cloud provider you'll need to replace the above IPs with the IPs dynamically assigned.

# Caching proxy setup for classes with poor Internet connectivity.
proxy_enabled = false

if (proxy_enabled)
  proxyHost='172.16.1.100'         # Enter the IP of the class' caching proxy.  172.16.1.100 is default Instructor VM for testing.
  proxy="http://#{proxyHost}:8123"
  base_box = "http://#{proxyHost}/student/precise-server-cloudimg-amd64-vagrant-disk1.box"
  apt_proxy_config = proxy
else
  proxy=''
  apt_proxy_config = 'DIRECT'
  base_box = 'http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box'
end

Vagrant.configure("2") do |config|
  config.apt_proxy.http = apt_proxy_config
  config.apt_proxy.https = apt_proxy_config
  config.vm.box_url = base_box

  config.vm.box = "precise-server-cloudimg-amd64"

  if (config.hostmanager.class == Vagrant::Config::V2::DummyConfig)
    puts "vagrant-hostmanager plugin not installed.  Please install it for automatic creation of /etc/hosts entries."
  else
    # This won't work with AWS provider tho....
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = false
  end

  # Install/Update guest additions
  if (config.vbguest.class == Vagrant::Config::V2::DummyConfig)
    puts "vagrant-vbguest plugin not installed.  Please install it for automatic installation of VirtualBox guest additions."
  else
    config.vbguest.auto_update = false
    config.vbguest.no_remote = false
  end

  ## Options below here usually don't need tweaking.  An exception would be for provisioning nodes in Amazon EC2.

  # VirtualBox configuration tweaks
  config.vm.provider :virtualbox do |v|
    # Leverage this Host OS's resolve.  This includes /etc/hosts entries
    v.customize ["modifyvm", :id, "--natdnshostresolver1","on"]
    # Memory customization doesn't work at the global level so we do it in each VM definition below.
    # v.customize ["modifyvm", :id, "--memory",256]
    v.gui = false
  end

  # AWS configuration tweaks
  #
  # Don't put security credentials directly in this file!
  # Create a new AWS user at https://console.aws.amazon.com/iam/home?#users and
  # download the credentials to ~/ec2/training.csv
  #
  # Note: The AWS credentials inside the Go pipeline config are Tim Brown's.  If you need to permanently change
  #       them edit puppet/go.pp, delete puppet/packaged/go.tgz, make packaged/go.tgz. You then need to copy go.tgz
  #       into /files under the gh-pages branch and commit.

  aws_credential_file = ::File.expand_path("~/.ec2/training.csv")
  if (::File.exists?(aws_credential_file))
    require 'csv'
    aws_credentials = ::CSV.table(aws_credential_file)
    puts "AWS credentials:" + aws_credentials[0][:access_key_id] + " " + aws_credentials[0][:secret_access_key]

    config.vm.provider :aws do |aws, override|
      aws.access_key_id = aws_credentials[0][:access_key_id]
      aws.secret_access_key = aws_credentials[0][:secret_access_key]
      aws.instance_type = "m1.small"
      # Create a security group with all TCP, UDP, and ICMP ports open.
      #  You shouldn't do this for most servers, but it's OK for the training class.
      aws.security_groups = "insecure"

      # If you change the AMI, consider changing it in http://github.com/TWInfraTraining/ec2-build-scripts/launch_ec2.py too.
      # Note that the AMI's may not be the same, as they vary per region.  launch_ec2.py launches into us-east-1 by default.
      aws.region = "us-west-1"
      aws.ami = "ami-c0eac285"
      # Create a key pair and download the .pem to ~/.ec2 -- reference it below
      aws.keypair_name = "training"
      override.ssh.username = "ubuntu"
      override.ssh.private_key_path = "#{ENV['HOME']}/.ec2/training.pem"

    end
  end


  ##########################################################################
  # Box Definitions - Students this is where you edit :-)
  ##########################################################################
  if (proxy_enabled)
    config.vm.provision :shell, :inline => "echo 'export http_proxy=#{proxy}' >> /etc/profile.d/proxy.sh"
  end

  config.vm.define :db do |my|
    my.vm.network :private_network, ip: "172.16.1.11"
    my.vm.hostname = "db"
    my.vm.provider :virtualbox do |vbox|
      vbox.name = my.vm.hostname
      vbox.customize ["modifyvm", :id, "--memory",512]
    end

    # This is a shell provisioner.  It sets up some basic prereqs for the course.
    my.vm.provision :shell, :path => "setup_node.sh" do |s|
      s.args = "'DBSG'"
    end

    my.vm.provision :puppet do |puppet|
      puppet.manifest_file ="db.pp"
      puppet.module_path = "modules"
    end

  end

  config.vm.define :web do |my|
    my.vm.network :private_network, ip: "172.16.1.10"
    my.vm.hostname = "web"
    my.vm.provider :virtualbox do |vbox|
      vbox.name = my.vm.hostname
      vbox.customize ["modifyvm", :id, "--memory",256]
    end

    # This is a shell provisioner.  It sets up some basic prereqs for the course.
    my.vm.provision :shell, :path => "setup_node.sh" do |s|
      s.args = "'WebSG'"
    end

    my.vm.provision :puppet do |puppet|
      puppet.manifest_file = "web.pp"
      puppet.module_path = "modules"
      puppet.options = "--verbose --debug"
    end
  end

  config.vm.define :monitor do |my|
    my.vm.network :private_network, ip: "172.16.1.2"
    my.vm.hostname="monitor"
    my.vm.provider :virtualbox do |vbox|
      vbox.name = my.vm.hostname
      vbox.customize ["modifyvm", :id, "--memory",256]
    end

    # This is a shell provisioner.  It sets up some basic prereqs for the course.
    my.vm.provision :shell, :path => "setup_node.sh" do |s|
      s.args = "'MonitorSG'"
    end

  end

  config.vm.define :go do |my|
    my.vm.network :private_network, ip: "172.16.1.3"
    my.vm.hostname = "go"

    my.vm.provider :virtualbox do |vbox|
      vbox.name = my.vm.hostname
      vbox.customize ["modifyvm", :id, "--memory",512]
    end

    my.vm.provider :aws do |aws|
      # aws.instance_type = "m1.large"
      aws.instance_type = "m1.xlarge"
      aws.tags = {
            'Name' => my.vm.hostname,
            'Student' => "#{ENV['USER']}-#{ENV['HOSTNAME']}"
          }
    end

    my.vm.provision :shell, :path => "setup_node.sh" do |s|
      s.args = "'GoServerSG'"
    end
  end
end
