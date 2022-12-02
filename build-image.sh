#!/bin/bash
source set-env.sh

image=$1
tag='latest'

if [ $# = 0 ]; then
	echo "Please use image name as the first argument!"
	exit 1
fi

mkdir -p ${DOCKER_HOME}/dist

# founction for delete images
function docker_rmi()
{
	echo "Docker Stoping and removing image: $1"
	for i in `sudo docker images bolthic/$1:$tag -q`
	do
		echo "   found image: $i"
		for c in `sudo docker ps -a -q -f ancestor=${i}`
		do
			echo "   stoping and removing container: $c"
  			sudo docker stop "$c"
  			sudo docker rm "$c"
		done
		echo "   removing image: $i"
		sudo docker rmi "$i"
	done
}


# founction for building hadoop
function hadoop_build()
{
	if [[ -e $DOCKER_HOME/dist/hadoop-${HADOOP_DISTRO}.tar.gz ]]; then
    	echo "   Found hadoop: `ls -l $DOCKER_HOME/dist/hadoop-${HADOOP_DISTRO}.tar.gz`"
	else
		echo "   missing $DOCKER_HOME/dist/hadoop-${HADOOP_DISTRO}.tar.gz"
		echo "   please get the hadoop distribution first "
		echo "   $DOKER_HOME/build_hadoop.sh"
		ls -l $DOCKER_HOME/dist
		exit 1
	fi
}


# founction for building hbase
function hbase_build(){
	if [[ -e $DOCKER_HOME/dist/hbase-$HBASE_DISTRO-bin.tar.gz ]]; then
    	echo "   Found hbase:  `ls -l $DOCKER_HOME/dist/hbase-$HBASE_DISTRO-bin.tar.gz`"
	else
		echo "   missing $DOCKER_HOME/dist/hbase-$HBASE_DISTRO-bin.tar.gz"
		echo "   please get the hbase distribution first"
		echo "   $HBASE_DISTRO/build_habase.sh"
		ls -l $DOCKER_HOME/dist
		exit 1
	fi
}


# founction for build images
function docker_build()
{
	cd ${DOCKER_HOME}
	cp -R $1 $TMP_DIR/
	cp -R dist $TMP_DIR/$1/
	cd $TMP_DIR/$1
	echo -e "\n\nsudo docker build -t bolthic/$1:$tag ."
	sudo docker build -t bolthic/$1:$tag . --build-arg hadoop=${HADOOP_DISTRO} --build-arg hbase=${HBASE_DISTRO}
	cd ${DOCKER_HOME}
}

echo "Building ${DOCKER_OWNER}/hadoop-hbase-${BUILD_VERSION} in ${DOCKER_HOME}"
echo "   Hadoop: ${HADOOP_VERSION}"
echo "   HBase:  ${HBASE_VERSION}"

sudo docker images >images.txt

#all image is based on dnsmasq. master and slaves are based on base image.
if [ $image == "all" ]
then
	docker_rmi hadoop-hbase-master
	docker_rmi hadoop-hbase-slave
	docker_rmi hadoop-hbase-base
	hadoop_build
	hbase_build
	docker_build hadoop-hbase-base
	docker_build hadoop-hbase-master
	docker_build hadoop-hbase-slave
elif [ $image == "hadoop-hbase-base" ]
then
	docker_rmi hadoop-hbase-base
	hadoop_build
	hbase_build
	docker_build hadoop-hbase-base
elif [ $image == "hadoop-hbase-master" ]
then
	docker_rmi hadoop-hbase-master
	docker_build hadoop-hbase-master
elif [ $image == "hadoop-hbase-slave" ]
then
	docker_rmi hadoop-hbase-slave
	docker_build hadoop-hbase-slave
else
	echo "The image name is wrong!"
fi

#docker_rmi hadoop-hbase-base

echo -e "\nimages before build"
cat images.txt
rm images.txt

echo -e "\nimages after build"
sudo docker images
