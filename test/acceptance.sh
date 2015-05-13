#!/bin/bash

function launch-mongo() {
  local id=$1;
  local node=$2;

  cat example/todomvc/db.json | \
  sed "s/\"id\":\"mongo\"/\"id\":\"mongo-$id\"/" | \
  sed "s/mongodata/mongodata$id/" | \
  sed "s/spinning/$disk/" | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
}

function launch-app() {
  local id=$1;
  
  cat example/todomvc/app.json | \
  sed "s/\"id\":\"app\"/\"id\":\"app-$id\"/" | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
}

function is-task-running() {
  curl -sS http://172.16.255.250:8080/v2/apps/$1 | jq .app.tasksRunning
}

function wait-for-task() {
  local running=$(is-task-running $1)
  while [[ "$running" == "null" ]]
  do
    echo "wait for task $1" && sleep 1
    running=$(is-task-running $1)
  done
  echo "task $1 is running"
  sleep 5
}


function run-test() {
  local unixsecs=$(date +%s)
  local flockervolumename="testflocker$unixsecs"

  #launch-mongo $unixsecs spinning
  wait-for-task mongo
  #launch-app $unixsecs
  wait-for-task app

  echo "apps are running!"
}

run-test