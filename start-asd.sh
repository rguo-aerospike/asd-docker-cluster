#!/bin/bash
# Dependencies: A Docker Swarm cluster pre-configured with
# clustering engine (consul/etcd/...)

set -x

MASTER=swarm-0
SIZE=3
#NAME=asdcluster 	# alphanumeric only, no spaces, dashes or underscores
NAME=$(basename $PWD)
export NAME

eval $(docker-machine env --swarm $MASTER)

#docker-compose -p $NAME --x-networking up -d	# brings up asd node
docker $(docker-machine config $MASTER) network create --driver overlay $NAME

docker-compose -p $NAME --x-networking scale aerospike=$SIZE # scale up

NODES=$(docker-compose -p $NAME ps aerospike| awk 'NR>=3  {print $1}')
FIRST_NODE=$(echo $NODES | awk '{print $1}')
for i in $NODES
do
	if [ "$i" == "$FIRST_NODE" ];then
		continue # skip self
	fi
	RETRY=1
	OK=""
	while [ "$OK" != "ok" ]; do
		# Exponential retry backoff
		sleep $RETRY
		OK=$(docker run --net $NAME aerospike/aerospike-tools asinfo -v "tip:host=$(docker inspect -f {{.NetworkSettings.Networks.$NAME.IPAddress}} $FIRST_NODE);port=3002" -h $i)
		RETRY=$(expr $RETRY \* 2)
	done
done
