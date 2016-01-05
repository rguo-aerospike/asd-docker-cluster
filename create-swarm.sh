#!/bin/bash

ENGINE_URL=https://get.docker.com/builds/Linux/x86_64/docker-1.9.1-rc1
B2D_URL=https://github.com/tianon/boot2docker-legacy/releases/download/v1.9.1-rc1/boot2docker.iso
DRIVER=vmwarefusion
SWARM_SIZE=3

if [ "$DRIVER" == "vmwarefusion" ]
then
  B2D_OPT="--vmwarefusion-boot2docker-url=$B2D_URL"
else if [ "$DRIVER" == "virtualbox" ]
then
  B2D_OPT=""
fi
fi

ENGINE_OPT="--engine-install-url=$ENGINE_URL"

# Craete the Machine to run Consul

docker-machine create \
  -d $DRIVER \
  $ENGINE_OPT \
  $B2D_OPT \
  swarm-consul 

docker $(docker-machine config swarm-consul) run \
        -d \
        --restart=always \
        -p "8500:8500" \
        -h "consul" \
        progrium/consul -server -bootstrap

# Create the machine that will be the swarm master        

docker-machine create \
  -d $DRIVER \
  $ENGINE_OPT \
  $B2D_OPT \
  --swarm \
  --swarm-master \
  --swarm-discovery="consul://$(docker-machine ip swarm-consul):8500" \
  --engine-opt="cluster-store=consul://$(docker-machine ip swarm-consul):8500" \
  --engine-opt="cluster-advertise=eth0:2376" \
  vm-swarm-0

# Create the rest of the machine sin the swarm cluster  

if [ ! -x "$(which parallel)" ]
then
    for i in `seq 1 $SWARM_SIZE`
    do
      docker-machine create \
        -d $DRIVER \
        $ENGINE_OPT \
        $B2D_OPT \
        --swarm \
        --swarm-discovery="consul://$(docker-machine ip swarm-consul):8500" \
        --engine-opt="cluster-store=consul://$(docker-machine ip swarm-consul):8500" \
        --engine-opt="cluster-advertise=eth0:2376" \
        vm-swarm-$i &
    done
else
  seq $SWARM_SIZE | parallel docker-machine create \
                        -d $DRIVER \
                        $ENGINE_OPT \
                        $B2D_OPT \
                        --swarm \
                        --swarm-discovery="consul://$(docker-machine ip swarm-consul):8500" \
                        --engine-opt="cluster-store=consul://$(docker-machine ip swarm-consul):8500" \
                        --engine-opt="cluster-advertise=eth0:2376" \
                        swarm-{}
fi


if docker network ls | grep -q "prod"
  then 
    echo "prod already created, removing first"
    docker $(docker-machine config --swarm swarm-0) network rm prod
fi

docker $(docker-machine config --swarm swarm-0) network create --driver overlay prod

eval $(docker-machine env --swarm swarm-0)
