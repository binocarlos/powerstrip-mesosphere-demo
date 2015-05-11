@test "run weave container and grab output" {
  local output=$(vagrant ssh node1 -c "sudo docker run -e \"WEAVE_CIDR=10.255.0.51/8\" binocarlos/powerstrip-weave-example hello world")
  echo "$output" > /tmp/weavetest.txt
}

@test "output contains 'hello world'" {
  cat /tmp/weavetest.txt | grep "hello world"
}