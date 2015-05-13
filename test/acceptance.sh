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
  
  cat example/todomvc/db.json | \
  sed "s/\"id\":\"app\"/\"id\":\"app-$id\"/" | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
}

function run-test() {
  local unixsecs=$(date +%s)
  local flockervolumename="testflocker$unixsecs"

  launch-mongo $unixsecs spinning
  launch-app $unixsecs
}

# we write the datestring into the guestbook with no spaces because URL encoding
writedate=`echo "$datestring" | sed 's/ //g'`

echo "writing data to node1 ($datestring)"
vagrant ssh node1 -c "sudo docker run --rm -v /flocker/$flockervolumename:/data busybox sh -c \"echo $datestring > /data/file.txt\""
echo "reading data from node2"
filecontent=`vagrant ssh node2 -c "sudo docker run --rm -v /flocker/$flockervolumename:/data busybox sh -c \"cat /data/file.txt\""`
if [[ $filecontent == *"$datestring"* ]]
then
  echo "Datestring: $datestring found!"
else
  do-error "The contents of the text file is not $datestring it is: $filecontent"
fi

echo "all tests were succesful"
exit 0