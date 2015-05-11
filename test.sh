#!/bin/bash

do-error() {
  echo "-------------------" >&2
  echo "ERROR!" >&2
  echo "$@" >&2
  exit 1
}

if [[ -f "/vagrant" ]]; then
  do-error "it looks like you are running the test from inside vagrant"
fi

datestring=$(date)
unixsecs=$(date +%s)
flockervolumename="testflocker$unixsecs"

# we write the datestring into the guestbook with no spaces because URL encoding
writedate=`echo "$datestring" | sed 's/ //g'`

echo "running test of basic Flocker migration without mesos"

# this will test that the underlying flocker mechanism is working
# it runs an Ubuntu container on node1 that writes to a Flocker volume
# it then runs another Ubuntu container on node2 that loads the data from this volume

echo "pull busybox onto node1"
vagrant ssh node1 -c "sudo docker pull busybox"
echo "pull busybox onto node2"
vagrant ssh node2 -c "sudo docker pull busybox"

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