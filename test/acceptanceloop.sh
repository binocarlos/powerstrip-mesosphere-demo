#!/bin/bash

#
# run acceptance.sh 3 times
#

# get the source folder for this script so it does not matter from where the tests are run
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_SRC="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


COUNTER=0
while [  $COUNTER -lt 3 ]; do
  bash $SCRIPT_SRC/acceptance.sh
  let COUNTER+=1
done