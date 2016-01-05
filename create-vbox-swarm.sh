#!/bin/bash

ENGINE_URL=https://get.docker.com/builds/Linux/x86_64/docker-1.9.1-rc1
B2D_URL=https://github.com/tianon/boot2docker-legacy/releases/download/v1.9.1-rc1/boot2docker.iso
#DRIVER=vmwarefusion
DRIVER=virtualbox
SWARM_SIZE=2


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
CONSUL_IP=$(docker-machine ip swarm-consul)

docker-machine create \
  -d $DRIVER \
  $ENGINE_OPT \
  $B2D_OPT \
  --swarm \
  --swarm-master \
  --swarm-discovery="consul://${CONSUL_IP}:8500" \
  --engine-opt="cluster-store=consul://${CONSUL_IP}:8500" \
  --engine-opt="cluster-advertise=eth1:2376" \
  swarm-0

# Create the rest of the machine sin the swarm cluster  

for i in `seq 1 $SWARM_SIZE`
do
  docker-machine create \
    -d $DRIVER \
    $ENGINE_OPT \
    $B2D_OPT \
    --swarm \
    --swarm-discovery="consul://${CONSUL_IP}:8500" \
    --engine-opt="cluster-store=consul://${CONSUL_IP}:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    swarm-$i &
done


if docker network ls | grep -q "prod"
  then
    echo "prod already created, removing first"
    docker $(docker-machine config --swarm swarm-0) network rm prod
fi

docker $(docker-machine config --swarm swarm-0) network create --driver overlay prod

eval $(docker-machine env --swarm swarm-0)
