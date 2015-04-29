#!/bin/bash -e

if [[ $# > 0 ]]; then
  if [[ "$1" == "slave" ]]; then
    export INSTALLER_TYPE=slave
  else
    export INSTALLER_TYPE=master
  fi
else
  export INSTALLER_TYPE=master
fi

echo "####################################################################"
echo "#################### Installing mesosphere $INSTALLER_TYPE #########"
echo "####################################################################"

export MASTER_IP=`cat /etc/flocker/master_address`
export SLAVE1_IP=`cat /etc/flocker/slave1_address`
export SLAVE2_IP=`cat /etc/flocker/slave2_address`

update-hosts() {
  ## Update /etc/hosts to add kube-master and kube-slave mapping ##
  echo "updating /etc/hosts to add master IP entry"
  echo "$MASTER_IP master.mesos" | sudo tee -a /etc/hosts
  echo "$SLAVE1_IP node1.mesos" | sudo tee -a /etc/hosts
  echo "$SLAVE2_IP node2.mesos" | sudo tee -a /etc/hosts
  cat /etc/hosts
}

setup-master() {
  mkdir -p /etc/zookeeper/conf
  mkdir -p /etc/mesos
  mkdir -p /etc/mesos-master
  mkdir -p /etc/marathon/conf
  echo "1" > /etc/zookeeper/conf/myid
  echo "server.1=$MASTER_IP:2888:3888" > /etc/zookeeper/conf/zoo.cfg
  echo "zk://$MASTER_IP:2181/mesos" > /etc/mesos/zk
  echo "1" > /etc/mesos-master/quorum
  echo "master.mesos" > /etc/mesos-master/hostname
  echo "master.mesos" > /etc/marathon/conf/hostname
  rm /etc/init/zookeeper.override
  rm /etc/init/mesos-master.override
  rm /etc/init/marathon.override
  sudo service zookeeper start
  sudo service mesos-master start
  sudo service marathon start
}

setup-slave() {
  sudo service marathon stop
  sudo sh -c "echo manual > /etc/init/marathon.override"
  mkdir -p /etc/mesos
  mkdir -p /etc/mesos-slave
  mkdir -p /etc/marathon/conf
  hostname=`cat /etc/flocker/hostname`
  echo "zk://$MASTER_IP:2181/mesos" > /etc/mesos/zk
  echo "$hostname.mesos" > /etc/mesos-slave/hostname
  echo "$hostname.mesos" > /etc/marathon/conf/hostname
  rm /etc/init/mesos-slave.override
  sudo service mesos-slave start
}

update-hosts

if [[ "$INSTALLER_TYPE" == "master" ]]; then
  setup-master
else
  setup-slave
fi