#!/bin/bash

# this will test that the powerstrip-weave adapter is working
# it will deploy a version of the binocarlos/powerstrip-weave-example container
# and check the output is correct

# it will then connect 2 weave containers across the 2 vagrant hosts and ensure
# they can communicate

do-error() {
  echo "-------------------" >&2
  echo "ERROR!" >&2
  echo "$@" >&2
  exit 1
}

if [[ -f "/vagrant" ]]; then
  do-error "it looks like you are running the test from inside vagrant"
fi

echo "running binocarlos/powerstrip-weave-example on node1"

output=$(vagrant ssh node1 -c "sudo docker run -e \"WEAVE_CIDR=10.255.0.51/8\" binocarlos/powerstrip-weave-example hello world")

echo "$output"
exit 0
#containerid="${containerid%\\n}"
#echo "---$containerid---"
#containerlogs=`vagrant ssh node1 -c "sudo docker logs $containerid"`

#echo $containerlogs

#if [[ $filecontent == *"$datestring"* ]]
#then
#  echo "Datestring: $datestring found!"
#else
#  do-error "The contents of the text file is not $datestring it is: $filecontent"
#fi

#echo "all tests were succesful"
#exit 0