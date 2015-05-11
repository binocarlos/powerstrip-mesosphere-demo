# cp -r ~/projects/powerstrip-weave ~/projects/powerstrip-mesosphere-demo/powerstrip-weave

# then vagrant ssh node1

sudo supervisorctl stop powerstrip-weave
sudo supervisorctl stop powerstrip

sudo DOCKER_HOST=unix:///var/run/docker.real.sock docker rm -f powerstrip
sudo DOCKER_HOST=unix:///var/run/docker.real.sock docker rm -f powerstrip-weave

sudo DOCKER_HOST=unix:///var/run/docker.real.sock docker run -ti --rm --name powerstrip-weave \
    --expose 80 \
    -v /vagrant/powerstrip-weave:/srv/app \
    --entrypoint="/bin/bash" \
    -e DOCKER_SOCKET="/var/run/docker.real.sock" \
    -v /var/run/docker.real.sock:/var/run/docker.sock \
    binocarlos/powerstrip-weave:latest

# then in another terminal
sudo supervisorctl start powerstrip
sudo docker run --rm -e "WEAVE_CIDR=10.255.0.51/8" binocarlos/powerstrip-weave-example hello world

# back on the host
cat test/testweave.json | \
curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps

# clean up on node1
sudo docker ps -a | grep powerstrip-weave-example | awk '{print $1}' | xargs sudo docker rm -f