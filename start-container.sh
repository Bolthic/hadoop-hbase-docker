#!/bin/bash

# run N slave containers
tag=$1
N=$2

if [ $# != 2  ]
then
	echo "Set first parametar as image version tag(e.g. 0.1) and second as number of nodes"
	exit 1
fi

PWD=`pwd`
USER=`id -u -n`
DOCKER_HOME=${DOCKER_HOME-$PWD}
DOCKER_LOCAL=${DOCKER_LOCAL-$DOCKER_HOME/local}
if [[ ! -d ${DOCKER_LOCAL} ]]; then
    mkdir -p ${DOCKER_LOCAL}
fi

# delete old master container and start new master container
sudo docker rm -f master.bolthic.com &> /dev/null
echo "start master container..."
sudo docker run -d -t --restart=always -v ${DOCKER_LOCAL}:/appli/local --dns 127.0.0.1 -p 8000:9870 -p 8001:9868 -p 8010:8088 -p 8020:60010 -p 8100:9864 -p 8200:8042 -p 8300:16030 -P --name master.bolthic.com -h master.bolthic.com -w /root bolthic/hadoop-hbase-master:$tag&> /dev/null

# 8000:9870 namenode
# 8000:9868 secondarynamenode
# 8010:8088 ressourcemanager
# 8020:60010 hmaster
# 81xx:9864 datanode
# 82xx:8042 nodemanger
# 83xx:16030 regionserver

# get the IP address of master container
FIRST_IP=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" master.bolthic.com)

# delete old slave containers and start new slave containers
i=1
while [ $i -le $N ]
do
	sudo docker rm -f slave$i.bolthic.com &> /dev/null
	echo "start slave$i container..."
	port=$(printf "%02d" $i)
	sudo docker run -d -t --restart=always --dns 127.0.0.1 -p 81$port:9864 -p 82$port:8042 -p 83$port:16030 -P --name slave$i.bolthic.com -h slave$i.bolthic.com -e JOIN_IP=$FIRST_IP bolthic/hadoop-hbase-slave:$tag &> /dev/null
	((i++))
done

# create a new Bash session in the master container
sudo docker exec -it master.bolthic.com bash
