#!/bin/bash

DRIVER=virtualbox
SWARM_SIZE=3

docker-machine create \
  -d $DRIVER \
   cluster-store                                                  
CLUSTER_STORE_IP=$(docker-machine ip cluster-store)

docker $(docker-machine config cluster-store) run -d \
    --restart="always" \
    --publish="2379:2379" \
     microbox/etcd:2.1.1 \
    -name etcd0 \
    -advertise-client-urls http://${CLUSTER_STORE_IP}:2379 \
    -listen-client-urls http://0.0.0.0:2379 \
    -initial-cluster-state new 

docker-machine create \
    -d $DRIVER \
    --swarm \
    --swarm-master \
    --swarm-discovery="etcd://${CLUSTER_STORE_IP}:2379/swarm" \
    --engine-opt="cluster-advertise=eth1:2376" \
    --engine-opt="cluster-store=etcd://${CLUSTER_STORE_IP}:2379/store" \
    swarm-0

for i in `seq 1 $SWARM_SIZE`
do
  docker-machine create \
    -d $DRIVER \
    --swarm \
    --swarm-discovery="etcd://${CLUSTER_STORE_IP}:2379/swarm" \
    --engine-opt="cluster-advertise=eth1:2376" \
    --engine-opt="cluster-store=etcd://${CLUSTER_STORE_IP}:2379/store" \
    swarm-$i &
done

if docker network ls | grep -q "prod"
  then 
    echo "prod already created, removing first"
    docker $(docker-machine config --swarm swarm-0) network rm prod
fi
    
docker $(docker-machine config --swarm swarm-0) network create --driver overlay prod

eval $(docker-machine env --swarm swarm-0)
