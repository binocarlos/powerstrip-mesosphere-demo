#!/bin/bash -e

echo "####################################################################"
echo "#################### Downloading mesosphere                 ########"
echo "####################################################################"

# install mesos and marathon and then disable all services
# this means we can share the same base vagrant box between master and slaves

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)

echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | \
  sudo tee /etc/apt/sources.list.d/mesosphere.list
sudo apt-get -y update

sudo apt-get -y install mesos marathon

sudo service marathon stop
sudo sh -c "echo manual > /etc/init/marathon.override"

sudo service mesos-master stop
sudo sh -c "echo manual > /etc/init/mesos-master.override"

sudo service mesos-slave stop
sudo sh -c "echo manual > /etc/init/mesos-slave.override"

sudo service zookeeper stop
sudo sh -c "echo manual > /etc/init/zookeeper.override"