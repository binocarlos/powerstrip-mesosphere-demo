## Powerstrip-mesosphere-demo

![warning](https://raw.github.com/binocarlos/powerstrip-k8s-demo/master/img/error.png "warning")
**Please note:** *because this demo uses [Powerstrip](https://github.com/clusterhq/powerstrip), which is only meant for prototyping Docker extensions, we do not recommend this configuration for anything approaching production usage. When Docker extensions become official, [Flocker](https://github.com/clusterhq/flocker) will support them. Until then, this is just a proof-of-concept.*

[Mesosphere](https://github.com/mesosphere) is building a [DataCenter Operating System](https://mesosphere.com/) and ClusterHQ have created [Flocker](https://github.com/clusterhq/flocker) - a data volume manager.

In this post, we will use [Mesos](https://github.com/apache/mesos) to manage the nodes, [Marathon](https://github.com/mesosphere/marathon) to schedule tasks onto nodes and [Flocker](https://github.com/clusterhq/flocker) to migrate data across nodes.

## Install
First you need to install:

 * [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
 * [Vagrant](http://www.vagrantup.com/downloads.html)

*We’ll use [Virtualbox](https://www.virtualbox.org/wiki/Downloads) to supply the virtual machines that our [Mesosphere](https://mesosphere.com/) cluster will run on.*

*We’ll use [Vagrant](http://www.vagrantup.com/downloads.html) to simulate our application stack locally. You could also run this demo on AWS or Rackspace with minimal modifications.*

## Demo

### Step 1: Start VMs

The first step is to clone this repo and start the 3 VMs.

```bash
$ git clone https://github.com/binocarlos/powerstrip-mesosphere-demo
$ cd powerstrip-mesosphere-demo
$ vagrant up
```

### Step 2: Open Marathon GUI

Now we open the marathon GUI so we can monitor our deployment.  Open a web browser and point it to this URL:

```
http://172.16.255.250:8080
```

### Step 3: Deploy the Mongo container

First - we deploy our Mongo container to Marathon using the `example/todomvc/db.json` config.  This will schedule the container onto the host with the `spinning` disk.

```bash
$ cat example/todomvc/db.json | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
```

### Step 4: Deploy the node.js container

Then we deploy our app container to Marathon using the `example/todomvc/app.json` config:

```bash
$ cat example/todomvc/app.json | \
  curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
```



## Reference

 * [Setting up Mesosphere on Ubuntu](https://docs.mesosphere.com/getting-started/datacenter/install/)
 * [Configure a Production-Ready Mesosphere Cluster](https://www.digitalocean.com/community/tutorials/how-to-configure-a-production-ready-mesosphere-cluster-on-ubuntu-14-04)