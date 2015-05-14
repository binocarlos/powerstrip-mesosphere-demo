#!/bin/bash

set -e

#
# powerstrip-mesos-demo acceptance test
#
# NOTE - you need jq installed on the host that runs these tests
# http://stedolan.github.io/jq/download/
#


# get the source folder for this script so it does not matter from where the tests are run
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_SRC="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# launch the mongo task via the Marathon REST api
function launch-mongo() {
  local id=$1;
  local disk=$2;

  echo "launching mongo - $id - $disk"

  cat $SCRIPT_SRC/../example/todomvc/db.json | \
  sed "s/\"id\":\"mongo\"/\"id\":\"mongo-$id\"/" | \
  sed "s/mongodata/mongodata$id/" | \
  sed "s/spinning/$disk/" | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
}

# launch the node.js task via the Marathon REST api
function launch-app() {
  local id=$1;
  
  echo "launching app - $id"
  cat $SCRIPT_SRC/../example/todomvc/app.json | \
  sed "s/\"id\":\"app\"/\"id\":\"app-$id\"/" | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
}

# use the Marathon REST api to remove the Mongo container
function delete-mongo() {
  curl -X "DELETE" http://172.16.255.250:8000/v2/apps/db-spinning
}

# parse the Marathon output for the status of a task
function is-mesos-task-running() {
  curl -sS http://172.16.255.250:8080/v2/apps/$1 | jq .app.tasksRunning
}

# continue to loop over is-mesos-task-running until it is ready
function wait-for-mesos-task() {
  local running=$(is-mesos-task-running $1)
  while [[ "$running" == "null" ]]
  do
    echo "wait for mesos task $1" && sleep 1    
    running=$(is-mesos-task-running $1)
  done
  echo "mesos task $1 is running"
  sleep 5
}

# told which node and which container - this will ssh to the node and
# run docker ps with a 'running' filter and grep the container name
function is-docker-container-running() {
  local node=$1
  local container=$2
  vagrant ssh $node -c "sudo docker ps --filter \"status=running\" | grep $container"
}

# keep looping over `is-docker-container-running` until it is
function wait-for-docker-container() {
  local node=$1
  local container=$2
  local running=$(is-docker-container-running $node $container)
  while [[ -z "$running" ]]
  do
    echo "waiting for docker container $container on $node"
    running=$(is-docker-container-running $node $container)
  done
  echo "docker container $container on node $node is running"
  sleep 1
}

# combine wait-for-mesos-task and wait-for-docker-container
function wait-for-job() {
  local task=$1
  local node=$2
  local container=$3

  echo ""
  echo "waiting for job $task - $node - $container"

  wait-for-mesos-task $task
  echo "waiting for docker container"
  wait-for-docker-container $node $container
}

# assuming the app is up and running - POST a JSON packet that represents
# the user having added a todo entry
function write-entry() {
  local unixsecs=$(date +%s)
  local text=$1;
  local order=$2;
  local id="$unixsecs.$order"

  cat $SCRIPT_SRC/test/entry.json | \
  sed "s/_ORDER_/$order/" | \
  sed "s/_TITLE_/$text/" | \
  sed "s/_ID_/$id/" | \
  curl -sS -i -H 'Content-type: application/json' -d @- http://172.16.255.251:8000/v1
}

# read the entries from the todo app
function check-entries() {
  curl -sS http://172.16.255.251:8000/v1
}


function run-test() {
  local id=$(date +%s)
  
  launch-mongo $id spinning
  launch-app $id

  wait-for-job mongo-$id node1 mongo:latest
  wait-for-job app-$id node1 binocarlos/powerstrip-mesosphere-demo:latest

  #sleep 2
  #write-entry "apples" 0
  #sleep 2
  #write-entry "oranges" 1
  #sleep 2
  #write-entry "pears" 2
  #sleep 2

  #check-entries
}

run-test