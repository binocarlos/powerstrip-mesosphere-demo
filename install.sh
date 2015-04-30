#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# a local way of writing a supervisor script
write-service() {
  local service="$1";

  cat << EOF > /etc/supervisor/conf.d/$service.conf
[program:$service]
command=bash /srv/install.sh $service
EOF
}

# a local way to start the services which calls the copied out version of this script
# this is because /vagrant is not mounted until later in the boot process
activate-service() {
  bash /srv/powerstrip-base-install/ubuntu/install.sh service $1
}

# if a vagrant halt -> vagrant up happens
# then this step is needed to bring up all the services again
cmd-boot() {
  cmd-bridge
  service docker start

  local hostname=`cat /etc/flocker/hostname`

  if [[ $hostname == "master" ]]; then
    supervisorctl start flocker-control
  else
    supervisorctl start flocker-zfs-agent
    supervisorctl start powerstrip-flocker
    supervisorctl start powerstrip-weave
    supervisorctl start powerstrip
  fi
}

remove-puppet-chef() {
  sudo service puppet stop
  sudo sh -c "echo manual > /etc/init/puppet.override"
  sudo service chef-client stop
  sudo sh -c "echo manual > /etc/init/chef-client.override"
}

# basic setup such as copy this script to /srv
init() {
  remove-puppet-chef
  
  cp -f /vagrant/install.sh /srv/install.sh

  #apt-get remove -y puppet
  #apt-get remove -y chef

  # pull any updates we have made to the powerstrip-base-install script
  # also bring in the k8s version
  cd /srv/powerstrip-base-install && git pull && git checkout k8s-compat

  echo "copying keys to /root/.ssh"
  cp /vagrant/insecure_private_key /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa
  chown root:root /root/.ssh/id_rsa
  cat /vagrant/insecure_public_key >> /root/.ssh/authorized_keys

  # include functions from the powerstrip lib
  . /srv/powerstrip-base-install/ubuntu/lib.sh

  powerstrip-base-install-configure-docker $@

  sleep 2
}

# here we build ontop of powerstrip-base-install and get swarm working on top
# the master expects the file /etc/flocker/swarm_addresses to be present
cmd-master() {

  # init copies the SSH keys and copies this script so it can be referenced by the supervisor scripts
  init $@

  # pull master images
  #bash /srv/powerstrip-base-install/ubuntu/install.sh pullimages master
  #powerstrip-base-install-pullimage swarm

  # get the control + swarm to work
  activate-service flocker-control
  #write-service swarm

  # start services
  supervisorctl reload

  bash /vagrant/mesosphere-install.sh master
  sleep 5
}

# /etc/flocker/my_address
# /etc/flocker/master_address - master address
cmd-minion() {

  # init copies the SSH keys and copies this script so it can be referenced by the supervisor scripts
  init $@

  # k8s does not use a specific docker version rather it just does
  # POST /containers/create
  cat << EOF > /etc/powerstrip-demo/adapters.yml
version: 1
endpoints:
  "POST /*/containers/create":
    pre: [flocker,weave]
  "POST /*/containers/*/start":
    pre: [flocker]
    post: [weave]
  "POST /containers/create":
    pre: [flocker,weave]
  "POST /containers/*/start":
    pre: [flocker]
    post: [weave]
adapters:
  flocker: http://flocker/flocker-adapter
  weave: http://weave/weave-adapter
EOF

  #DOCKER_HOST=unix:///var/run/docker.real.sock docker pull binocarlos/powerstrip-k8s-demo:frontend

  # pull minion images
  #powerstrip-base-install-pullimage ubuntu:latest
  #bash /srv/powerstrip-base-install/ubuntu/install.sh pullimages minion

  # get the flocker / weave / powerstrip services to work
  activate-service flocker-zfs-agent
  activate-service powerstrip-flocker
  activate-service powerstrip-weave
  activate-service powerstrip
  #write-service tcptunnel


  # start services
  supervisorctl reload

  echo 2000 > /proc/sys/net/ipv4/neigh/default/base_reachable_time_ms

  bash /vagrant/mesosphere-install.sh slave
  sleep 5
}

cmd-weave() {
  DOCKER_HOST="unix:///var/run/docker.real.sock" \
  docker run -ti --rm \
    -e DOCKER_SOCKET="/var/run/docker.real.sock" \
    -v /var/run/docker.real.sock:/var/run/docker.sock \
    binocarlos/powerstrip-weave $@
}

cmd-debug() {
  local addr=`cat /etc/flocker/my_address`
  cat << EOF > /etc/powerstrip-demo/adapters.yml
version: 1
endpoints:
  "POST /containers/create":
    pre: [debug,flocker,weave,debug]
  "POST /containers/*/start":
    post: [debug,weave,debug]
adapters:
  flocker: http://flocker/flocker-adapter
  weave: http://weave/weave-adapterde
  debug: http://$addr:8086
EOF
  DOCKER_HOST=unix:///var/run/docker.real.sock docker pull binocarlos/powerstrip-debug
  DOCKER_HOST=unix:///var/run/docker.real.sock docker run --name debug -d  -p 8086:80 binocarlos/powerstrip-debug
  supervisorctl stop powerstrip
  DOCKER_HOST=unix:///var/run/docker.real.sock docker rm -f powerstrip
  supervisorctl start powerstrip
}

usage() {
cat <<EOF
Usage:
install.sh master
install.sh minion
install.sh weave
install.sh debug
install.sh boot
install.sh help
EOF
  exit 1
}

main() {
  case "$1" in
  master)                   shift; cmd-master $@;;
  minion)                   shift; cmd-minion $@;;
  weave)                    shift; cmd-weave $@;;
  debug)                    shift; cmd-debug $@;;
  boot)                     shift; cmd-boot $@;;
  *)                        usage $@;;
  esac
}

main "$@"