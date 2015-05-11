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
export MY_ADDRESS=`cat /etc/flocker/my_address`

update-hosts() {
  ## Update /etc/hosts to add kube-master and kube-slave mapping ##
  echo "updating /etc/hosts to add master IP entry"
  echo "127.0.0.1 localhost" > /etc/hosts
  echo "$MASTER_IP master" | sudo tee -a /etc/hosts
  echo "$SLAVE1_IP node1" | sudo tee -a /etc/hosts
  echo "$SLAVE2_IP node2" | sudo tee -a /etc/hosts
  cat /etc/hosts
}

setup-master() {
  mkdir -p /etc/zookeeper/conf
  mkdir -p /etc/mesos
  mkdir -p /etc/mesos-master
  mkdir -p /etc/marathon/conf
  echo "1" > /etc/zookeeper/conf/myid
  echo "server.1=$MASTER_IP:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
  echo "zk://$MASTER_IP:2181/mesos" > /etc/mesos/zk
  cp /etc/mesos/zk /etc/marathon/conf/master
  echo "zk://$MASTER_IP:2181/marathon" > /etc/marathon/conf/zk
  #echo "1" > /etc/mesos-master/quorum
  echo "$MY_ADDRESS" > /etc/mesos-master/hostname
  echo "$MY_ADDRESS" > /etc/mesos-master/ip
  echo "$MY_ADDRESS" > /etc/marathon/conf/hostname
  
  rm /etc/init/zookeeper.override
  rm /etc/init/mesos-master.override
  rm /etc/init/marathon.override
  sudo service zookeeper start
  sudo service mesos-master start
  sudo service marathon start
}

setup-slave() {
  mkdir -p /etc/mesos
  mkdir -p /etc/mesos-slave
  mkdir -p /etc/marathon/conf
  echo 'docker,mesos' > /etc/mesos-slave/containerizers
  cp /etc/flocker/mesos-attributes /etc/mesos-slave/attributes
  echo '5mins' > /etc/mesos-slave/executor_registration_timeout
  echo "zk://$MASTER_IP:2181/mesos" > /etc/mesos/zk
  echo "ports:[7000-9000]" > /etc/mesos-slave/resources
  echo "$MY_ADDRESS" > /etc/mesos-slave/hostname
  echo "$MY_ADDRESS" > /etc/mesos-slave/ip
  echo "$MY_ADDRESS" > /etc/marathon/conf/hostname
  rm /etc/init/mesos-slave.override

  sleep 10
  sudo service mesos-slave start
}

update-hosts

if [[ "$INSTALLER_TYPE" == "master" ]]; then
  setup-master
else
  setup-slave
fi