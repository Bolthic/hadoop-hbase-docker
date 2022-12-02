#!/bin/bash

# run N slave containers
tag=$1
N=$2

if [ $# != 2  ]
then
	echo "Set first parametar as image version tag(e.g. 0.1) and second as number of nodes"
	exit 1
fi

# delete old master container and start new master container
sudo docker rm -f master.bolthic.com &> /dev/null
echo "start master container..."
sudo docker run -d -t --restart=always --dns 127.0.0.1 -P --name master.bolthic.com -h master.bolthic.com -w /root bolthic/hadoop-hbase-master:$tag&> /dev/null

# get the IP address of master container
FIRST_IP=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" master.bolthic.com)

# delete old slave containers and start new slave containers
i=1
while [ $i -le $N ]
do
	sudo docker rm -f slave$i.bolthic.com &> /dev/null
	echo "start slave$i container..."
	sudo docker run -d -t --restart=always --dns 127.0.0.1 -P --name slave$i.bolthic.com -h slave$i.bolthic.com -e JOIN_IP=$FIRST_IP bolthic/hadoop-hbase-slave:$tag &> /dev/null
	((i++))
done

# create a new Bash session in the master container
sudo docker exec -it master.bolthic.com bash
