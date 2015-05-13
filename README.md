## Powerstrip-mesosphere-demo

![warning](https://raw.github.com/binocarlos/powerstrip-k8s-demo/master/img/error.png "warning")
**Please note:** *because this demo uses [Powerstrip](https://github.com/clusterhq/powerstrip), which is only meant for prototyping Docker extensions, we do not recommend this configuration for anything approaching production usage. When Docker extensions become official, [Flocker](https://github.com/clusterhq/flocker) and [Weave](https://github.com/weaveworks/weave) will support them. Until then, this is just a proof-of-concept.*

We [recently showed](https://clusterhq.com/blog/migration-database-container-docker-swarm/) how you could use [Docker Swarm](https://github.com/docker/swarm) to migrate a database container and its volume between hosts using only the native [Docker Swarm](https://github.com/docker/swarm) CLI.  We [then demonstrated](https://clusterhq.com/blog/data-migration-kubernetes-flocker/) how to use [Kubernetes](https://github.com/googlecloudplatform/kubernetes) to acheive the same thing.

[Mesosphere](https://github.com/mesosphere) are building a [DataCenter Operating System](https://mesosphere.com/), ClusterHQ have created [Flocker](https://github.com/clusterhq/flocker) - a data volume manager and Weaveworks have created [Weave](https://github.com/weaveworks/weave), a virtual overlay network for Docker containers.

In this post, we will use [Mesos](https://github.com/apache/mesos) to manage our nodes, [Marathon](https://github.com/mesosphere/marathon) to schedule tasks onto nodes, [Flocker](https://github.com/clusterhq/flocker) to migrate data across nodes and [Weave](https://github.com/weaveworks/weave) to connect the containers together.

## Scenario

Our demo is a Backbone version of the classic [TodoMVC](http://todomvc.com/) application.  It is plugged into a node.js [TodoMVCBackend](http://www.todobackend.com/) which saves its data inside a [MongoDB](https://www.mongodb.org/) container.

We have added attributes to the 2 Mesos slaves - `disk=spinning` and `disk=ssd` to represent the types of disk they have.  The Mongo container is first allocated onto the node with the spinning disk and then migrated (along with its data) onto the node with an ssd drive.

This represents a real world migration where we realise that our database server needs a faster disk.

#### Before migration
![before migration](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/before.png "fig 1. before migration")
###### *fig 1. node.js container accessing Mongo container on node 1*

#### After migration
![after migration](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/after.png "fig 2. after migration")
###### *fig 2. Mongo container & data volume migrated to node 2*


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

### Step 2: Open Marathon/Mesos GUI

Now we open the Marathon GUI so we can monitor our deployment.  Open a web browser and point it to this URL:

```
http://172.16.255.250:8080
```

IMG: marathon screen shot (empty)

Also - we can open the Mesos GUI to monitor the underlying resource usage.  Open another web browser and point it to this URL:

```
http://172.16.255.250:5050
```

IMG: mesos screen shot (empty)

### Step 3: Deploy the Mongo container

First - we deploy our Mongo container to Marathon using the `example/todomvc/db.json` config.  This will schedule the container onto the host with the `spinning` disk.

```bash
$ cat example/todomvc/db.json \
  | curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
```

### Step 4: Deploy the node.js container

Then we deploy our app container to Marathon using the `example/todomvc/app.json` config:

```bash
$ cat example/todomvc/app.json \
  | curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
```

### Step 5: Check deployment

The Marathon GUI should display the 2 deployments.  

IMG: marathon screen shot (with 2 apps)

We can also check the status by using the REST API:

```bash
$ curl http://172.16.255.250:8080/v2/tasks
```

### Step 6: Add some data

Next - open the application in a browser and add some todo entries.  Once you have typed an entry press `Enter` to submit it to the database.

```
http://172.16.255.251:8000/
```

IMG: todomvc screenshot

### Step 7: Stop Mongo container

Now - we stop the Mongo container in preparation for moving it to node2:

```bash
$ curl -X "DELETE" http://172.16.255.250:8080/v2/apps/mongo
```

### Step 8: Re-deploy the Mongo container

Next - we use the same deployment file but replace the constraint so the Mongo container is scheduled onto the node with the SSD disk:

```bash
$ cat example/todomvc/db.json \
  | sed 's/spinning/ssd/' \
  | curl -i -H 'Content-type: application/json' -d @- http://172.16.255.250:8080/v2/apps
```

### Step 9: Check deployment

Now we have moved the Mongo container - lets check the Marathon GUI for the deployment status.

IMG: marathon screen shot (with 2 apps)

### Step 10: Check data

Now we reload the application in a browser and check that the todo entries we added before are still there (meaning we have migrated the data successfully)

```
http://172.16.255.251:8000/
```

## Reference

 * [Setting up Mesosphere on Ubuntu](https://docs.mesosphere.com/getting-started/datacenter/install/)
 * [Configure a Production-Ready Mesosphere Cluster](https://www.digitalocean.com/community/tutorials/how-to-configure-a-production-ready-mesosphere-cluster-on-ubuntu-14-04)