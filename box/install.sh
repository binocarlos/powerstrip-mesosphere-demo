#!/bin/bash

export FLOCKER_BASE_REPO=${FLOCKER_BASE_REPO:=https://github.com/binocarlos/flocker-base-install}
export POWERSTRIP_BASE_REPO=${POWERSTRIP_BASE_REPO:=https://github.com/binocarlos/powerstrip-base-install}
export POWERSTRIP_FLOCKER_IMAGE=${POWERSTRIP_FLOCKER_IMAGE:=clusterhq/powerstrip-flocker:k8s-compat}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "POWERSTRIP_FLOCKER_IMAGE=clusterhq/powerstrip-flocker:k8s-compat" >> /etc/environment

apt-get update
apt-get install -y \
  git

cd /srv
git clone $FLOCKER_BASE_REPO
. /srv/flocker-base-install/ubuntu/install.sh
flocker-base-install

cd /srv
git clone $POWERSTRIP_BASE_REPO
. /srv/powerstrip-base-install/ubuntu/lib.sh
powerstrip-base-install-setup
powerstrip-base-install-pullimages master
powerstrip-base-install-pullimages minion
powerstrip-base-install-powerstrip-config

powerstrip-base-install-pullimage mongo
powerstrip-base-install-pullimage binocarlos/powerstrip-mesosphere-demo

bash /vagrant/mesosphere-download.sh

sh -c "echo manual > /etc/init/puppet.override"
sh -c "echo manual > /etc/init/chef-client.override"
service chef-client stop
service puppet stop
apt-get remove -y --auto-remove puppet
apt-get purge -y --auto-remove puppet
apt-get remove -y --auto-remove chef
apt-get purge -y --auto-remove chef

apt-get clean