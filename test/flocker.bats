@test "Pull busybox onto node1" {
  skip
  vagrant ssh node1 -c "sudo docker pull busybox"
  local images=`vagrant ssh node1 -c "sudo docker images"`
  [[ $images == *"busybox"* ]]
}

@test "Pull busybox onto node2" {
  skip
  vagrant ssh node2 -c "sudo docker pull busybox"
  local images=`vagrant ssh node2 -c "sudo docker images"`
  [[ $images == *"busybox"* ]]
}

@test "writing data to node1 ($datestring) and read from node2" {
  bash $BATS_TEST_DIRNAME/flocker.sh
}