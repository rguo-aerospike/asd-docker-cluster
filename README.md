# asd-docker-cluster
For OSX

This collection of scripts and configs would quickly deploy a docker cluster on your OSX machine.
The docker host cluster will be managed by docker-machine and created using docker-swarm.
The container cluster and stack will be managed by docker-compose.

##Requirements
Install docker-toolbox:
https://docs.docker.com/engine/installation/mac/


##Usage
Create your docker swarm environment with one of the following scripts on OSX:
* **create-swarm.sh**: Vmware swarm using consul
* **create-vbox-swarm.sh**:	VirtualBox swarm using consul
* **create-vbox-swarm-etcd.sh**: VirtualBox swarm using etcd

The above scripts will create a docker cluster using docker-machine and docker-swarm. Swarm will be managed via either consul or etcd depending on which one is used.
An overlay network named `prod` will be created as well. Docker client settings are also updated to point toward the SWARM endpoint.

In case you accidentally close the terminal, you can get the docker client settings back via:
`eval $(docker-machine env --swarm swarm-0)`

##Start interlock instance
Obsolete. See [next section](#let-compose-set-everything-up).
**Manual Method**
Run directly from dockerhub image:
    
    docker run --name interlock --net prod -e AEROSPIKE_NETWORK_NAME=prod --rm  -v /var/lib/boot2docker:/etc/docker  aerospike/interlock --swarm-url=$DOCKER_HOST --swarm-tls-ca-cert=/etc/docker/ca.pem --swarm-tls-cert=/etc/docker/server.pem --swarm-tls-key=/etc/docker/server-key.pem --debug -p aerospike start

**Old way**
Build and run the interlock container

    eval $(docker-machine env --swarm swarm-0)
    git clone git@github.com:aerospike/interlock.git
    cd interlock
    make build-container && docker build -t interlock .
    docker run --name interlock --net prod -e AEROSPIKE_NETWORK_NAME=prod --rm  -v /var/lib/boot2docker:/etc/docker  interlock --swarm-url=$DOCKER_HOST --swarm-tls-ca-cert=/etc/docker/ca.pem --swarm-tls-cert=/etc/docker/server.pem --swarm-tls-key=/etc/docker/server-key.pem --debug -p aerospike start

##Let Compose set everything up

    eval $(docker-machine env --swarm swarm-0)
    docker-compose --x-networking --x-network-driver overlay -p prod up -d
    docker-compose --x-networking --x-network-driver overlay -p prod scale aerospike=SCALE


##Confirm cluster:

`docker run --rm --net prod aerospike/aerospike-tools asadm -e i -h prod_aerospike_1`


## Data Persistance

**Host Data Persistence**
Data can be persisted to the host that's running the Docker daemon. 

    aerospike:
      image: aerospike/aerospike-server
      volumes:
        - /host/data/dir:/opt/aerospike/data
       ...

In the above example, each docker host would have the directory `/host/data/dir` created if not already exists. Aerospike will then write to this volume which is mounted under `/opt/aerospike/data`.

**Data-only Container**
A data-only container is another option to persist data.
We can define a data-only container that exposes volumes to be used by Aerospike.
   
    data:
      image:aerospike/aerospike-server
      entrypoint: tail -f /dev/null
      volumes:
        - /opt/aerospike/data
    aerospike:
      image:aerospike/aerospike-server
      volumes_from:
        - data
      ....

Note that the `volumes_from` parameter replaces the corresponding `volume` parameter from the `aerospike` service definition. The aerospike-server image is chosen for the data-only container to minimize disk usage and the entrypoint overridden to trick docker-compose into keeping the data-only container. Scaling should be done with the data-only container first.

A data-only container would give you flexibility that host-based persistence would not, as there is no longer a requirement for identical host hardware configurations.
