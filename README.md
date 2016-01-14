# asd-docker-cluster
For OSX

##Requirements
Install docker-toolbox:
https://docs.docker.com/engine/installation/mac/


##Usage
Create your docker swarm environment with one of the following scripts on OSX:
* create-swarm.sh		Vmware swarm using consul
* create-vbox-swarm.sh		VirtualBox swarm using consul
* create-vbox-swarm-etcd.sh	VirtualBox swarm using etcd

The above scripts will create a docker cluster using docker-machine and docker-swarm. Swarm will be managed via either consul or etcd depending on which one is used.
An overlay network named `prod` will be created as well. Docker client settings are also updated to point toward the SWARM endpoint.

In case you accidentally close the terminal, you can get the docker client settings back via:
`eval $(docker-machine env --swarm swarm-0)`

##Start interlock instance
Run directly from dockerhub image:
    
    docker run --name interlock --net prod -e AEROSPIKE_NETWORK_NAME=prod --rm  -v /var/lib/boot2docker:/etc/docker  rguo/interlock --swarm-url=$DOCKER_HOST --swarm-tls-ca-cert=/etc/docker/ca.pem --swarm-tls-cert=/etc/docker/server.pem --swarm-tls-key=/etc/docker/server-key.pem --debug -p aerospike start

**Old way**
Build and run the interlock container

    eval $(docker-machine env --swarm swarm-0)
    git clone git@github.com:rguo-aerospike/interlock.git
    cd interlock
    make build-container && docker build -t interlock .
    docker run --name interlock --net prod -e AEROSPIKE_NETWORK_NAME=prod --rm  -v /var/lib/boot2docker:/etc/docker  interlock --swarm-url=$DOCKER_HOST --swarm-tls-ca-cert=/etc/docker/ca.pem --swarm-tls-cert=/etc/docker/server.pem --swarm-tls-key=/etc/docker/server-key.pem --debug -p aerospike start

##Create ASD instances

    eval $(docker-machine env --swarm swarm-0)
    docker-compose --x-networking --x-network-driver overlay -p prod scale aerospike=SCALE


##Confirm cluster:

`docker run --rm --net prod aerospike/aerospike-tools asadm -e i -h prod_aerospike_1`
