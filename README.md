## Powerstrip-mesosphere-demo

![warning](https://raw.github.com/binocarlos/powerstrip-k8s-demo/master/img/error.png "warning")
**Please note:** *because this demo uses [Powerstrip](https://github.com/clusterhq/powerstrip), which is only meant for prototyping Docker extensions, we do not recommend this configuration for anything approaching production usage. When Docker extensions become official, [Flocker](https://github.com/clusterhq/flocker) and [Weave](https://github.com/weaveworks/weave) will support them. Until then, this is just a proof-of-concept.*

[![asciicast](https://asciinema.org/a/76dojidwailodmxdjfyw5yfyw.png)](https://asciinema.org/a/76dojidwailodmxdjfyw5yfyw)

We [recently showed](https://clusterhq.com/blog/migration-database-container-docker-swarm/) how you could use Docker Swarm to migrate a database container and its volume between hosts using only the native Docker Swarm  CLI.  We [then demonstrated](https://clusterhq.com/blog/data-migration-kubernetes-flocker/) how to use Kubernetes to achieve the same thing.

[Mesosphere](https://github.com/mesosphere) are building a [Data Center Operating System](https://mesosphere.com/), ClusterHQ have created [Flocker](https://github.com/clusterhq/flocker) - a data volume manager and Weaveworks have created [Weave](https://github.com/weaveworks/weave), a virtual overlay network for Docker containers.

Ideally – we want to use all of these systems together so we can use orchestration tools to control storage and networking.  That is the aim of this demo, to show how using Powerstrip, we can extend Docker with tools like Flocker and Weave and still use orchestration tools like Mesos & Marathon.

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

Lets begin!

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

![marathon web gui](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/marathon-empty.png "fig 3. marathon web gui")
###### *fig 3. the Marathon web GUI before deployment*

Also - we can open the Mesos GUI to monitor the underlying resource usage.  Open another web browser and point it to this URL:

```
http://172.16.255.250:5050
```

![mesos web gui](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/mesos-empty.png "fig 4. mesos web gui")
###### *fig 4. the Mesos web GUI before deployment*

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

![marathon web gui](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/marathon-apps1.png "fig 5. marathon web gui")
###### *fig 5. the Marathon web GUI after deployment*

We can also check the status by using the REST API:

```bash
$ curl http://172.16.255.250:8080/v2/tasks
```

### Step 6: Add some data

Next - open the application in a browser and add some todo entries.  Once you have typed an entry press `Enter` to submit it to the database.

```
http://172.16.255.251:8000/
```

![todomvc app](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/todomvc.png "fig 6. todomvc app")
###### *fig 6. The todoMVC application*

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

![marathon web gui](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/marathon-apps2.png "fig 7. marathon web gui")
###### *fig 7. the Marathon web GUI after the 2nd deployment*

### Step 10: Check data

Now we reload the application in a browser and check that the todo entries we added before are still there (meaning we have migrated the data successfully)

```
http://172.16.255.251:8000/
```

note: it sometimes take 10 seconds for the mongo container to be deployed and for the node.js container to connect to it.  If the data does not appear press refresh after 10 seconds.

## How it works

The key part of this demonstration is the usage of [Flocker](https://github.com/clusterhq/flocker) to migrate data from one server to another. To make [Flocker](https://github.com/clusterhq/flocker) work natively with Mesos and Marathon, we've used [Powerstrip](https://github.com/clusterhq/powerstrip). [Powerstrip](https://github.com/clusterhq/powerstrip) is an open-source project we started to prototype Docker extensions. 

This demo uses the [Flocker](https://github.com/clusterhq/flocker) extension prototype ([powerstrip-flocker](https://github.com/clusterhq/powerstrip-flocker)). Once the official Docker extensions mechamisn is released, [Powerstrip](https://github.com/clusterhq/powerstrip) will go away and you’ll be able to use Flocker directly with Mesos & Marathon (or Docker Swarm, or Kubernetes) to perform database migrations.

We have installed [Powerstrip](https://github.com/clusterhq/powerstrip) and [powerstrip-flocker](https://github.com/clusterhq/powerstrip-flocker) on each host.  This means that when Marathon starts a container with volumes - [powerstrip-flocker](https://github.com/clusterhq/powerstrip-flocker) is able to prepare / migrate the required data volumes before docker starts the container.

### Mesos Cluster
The master node (which controls the cluster) is running the following components:

 * mesos-master - the master node for the mesos cluster
 * marathon - a mesos framework that runs long running processes
 * zookeeper - a distributed key/value store
 * flocker-control-service - the control service for the Flocker cluster

The 2 slave nodes each run:

 * mesos-slave - the slave process that communicates with the mesos-master
 * flocker-zfs-agent - the flocker slave process that communicates with the flocker-control-service
 * powerstrip - the prototyping tool for Docker extensions
 * powerstrip-flocker - a powerstrip adapter that creates ZFS volumes for containers
 * powerstrip-weave - a powerstrip adapter that networks containers together across hosts

![mesos diagram](https://raw.github.com/binocarlos/powerstrip-mesosphere-demo/master/img/overview.png "fig 8. mesos")
###### *fig 8. overview of the Kubernetes cluster*

## Conclusion
Mesos and Marathon are powerful tools to manage a cluster of machines as though they are one large computer.  We have shown in this demo that you can extend the behaviour of Mesos slaves using [Powerstrip](https://github.com/clusterhq/powerstrip) adapters (and soon official Docker extensions).

This demo made use of local storage for your data volumes. Local storage is fast and cheap and with [Flocker](https://github.com/clusterhq/flocker), it’s also portable between servers and even clouds. 

We are also working on adding support for block storage so you can use that with your application.

## Notes

## run tests

To run the acceptance tests:

```bash
$ make test
```

NOTE: you need [jq](http://stedolan.github.io/jq/) installed on the machine that will run the tests

## Reference

 * [Setting up Mesosphere on Ubuntu](https://docs.mesosphere.com/getting-started/datacenter/install/)
 * [Configure a Production-Ready Mesosphere Cluster](https://www.digitalocean.com/community/tutorials/how-to-configure-a-production-ready-mesosphere-cluster-on-ubuntu-14-04)