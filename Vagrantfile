# -*- mode: ruby -*-
# vi: set ft=ruby :

# This requires Vagrant 1.6.2 or newer (earlier versions can't reliably
# configure the Fedora 20 network stack).
Vagrant.require_version ">= 1.6.2"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
 
  config.vm.box = "powerstrip-mesosphere-demo-v3-local-test2"
  #config.vm.box_url = "http://storage.googleapis.com/experiments-clusterhq/orchestration-demos/powerstrip-mesosphere-demo-v3.box"
  config.vm.box_url = "file:///Users/kai/projects/powerstrip-mesosphere-demo/box/powerstrip-mesosphere-demo-v3.box"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  config.vm.define "master" do |master|
    master.vm.network :private_network, :ip => "172.16.255.250"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |v|
      v.memory = 1536
    end
    master.vm.provision "shell", inline: <<SCRIPT
mkdir -p /etc/flocker
echo 172.16.255.250 > /etc/flocker/my_address
echo 172.16.255.250 > /etc/flocker/master_address
echo 172.16.255.251 > /etc/flocker/slave1_address
echo 172.16.255.252 > /etc/flocker/slave2_address
echo master > /etc/flocker/hostname
bash /vagrant/install.sh master
SCRIPT
  end

  config.vm.define "node1" do |node1|
    node1.vm.network :private_network, :ip => "172.16.255.251"
    node1.vm.hostname = "node1"
    node1.vm.provider "virtualbox" do |v|
      v.memory = 1536
    end
    node1.vm.provision "shell", inline: <<SCRIPT
mkdir -p /etc/flocker
echo 172.16.255.251 > /etc/flocker/my_address
echo 172.16.255.250 > /etc/flocker/master_address
echo 172.16.255.251 > /etc/flocker/slave1_address
echo 172.16.255.252 > /etc/flocker/slave2_address
echo node1 > /etc/flocker/hostname
echo disk:spinning > /etc/flocker/mesos-attributes
bash /vagrant/install.sh minion
SCRIPT
  end

  config.vm.define "node2" do |node2|
    node2.vm.network :private_network, :ip => "172.16.255.252"
    node2.vm.hostname = "node2"
    node2.vm.provider "virtualbox" do |v|
      v.memory = 1536
    end
    node2.vm.provision "shell", inline: <<SCRIPT
mkdir -p /etc/flocker
echo 172.16.255.252 > /etc/flocker/my_address
echo 172.16.255.250 > /etc/flocker/master_address
echo 172.16.255.251 > /etc/flocker/slave1_address
echo 172.16.255.252 > /etc/flocker/slave2_address
echo 172.16.255.251 > /etc/flocker/peer_address
echo node2 > /etc/flocker/hostname
echo disk:ssd > /etc/flocker/mesos-attributes
bash /vagrant/install.sh minion
SCRIPT
  end
end
