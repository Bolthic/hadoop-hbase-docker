#!/bin/bash

image=$1
tag='latest'

DOCKER_HOME=`pwd`
source set-env.sh

if [ $# = 0 ]; then
	echo "Please use image name as the first argument!"
	exit 1
fi
mkdir -p ${DOKER_HOME}/dist

# founction for delete images
function docker_rmi()
{
	echo -e "\n\nsudo docker rmi ferune/$1:$tag"
	sudo docker rmi ferune/$1:$tag
}


# founction for building hadoop
function hadoop_build()
{
	if [[ -e $DOCKER_HOME/dist/hadoop-${distro}.tar.gz ]]; then
    	echo "   already built: `ls -l $DOCKER_HOME/dist/hadoop-${HADOOP_DISTRO}.tar.gz`"
	else
		$DOKER_HOME/build_hadoop.sh
	fi
}


# founction for building hbase
function hbase_build(){
	if [[ -e $DOCKER_HOME/dist/hbase-$distro-bin.tar.gz ]]; then
    	echo "   already built: `ls -l hadoop-dist/target/hadoop-${HBASE_DISTRO}.tar.gz`"
	else
		$DOKER_HOME/build_hbase.sh
	fi
}


# founction for build images
function docker_build()
{
	cd $1
	echo -e "\n\nsudo docker build -t ferune/$1:$tag ."
	time sudo docker build -t ferune/$1:$tag .
	cd ..
}

echo "Building ${DOCKER_OWNER}/hadoop-hbase-${BUILD_VERSION} in ${DOCKER_HOME}"
echo "   Hadoop: ${HADOOP_VERSION}"
echo "   HBase:  ${HBASE_VERSION}"

echo -e "\ndocker rm -f slave1.ferune.fr slave2.ferune.fr master.ferune.fr"
sudo docker rm -f slave1.ferune.fr slave2.ferune.fr master.ferune.fr

sudo docker images >images.txt

#all image is based on dnsmasq. master and slaves are based on base image.
if [ $image == "hadoop-hbase-base" ]
then
	docker_rmi hadoop-hbase-master
	docker_rmi hadoop-hbase-slave
	docker_rmi hadoop-hbase-base
	hadoop_build
	hbase_build
	docker_build hadoop-hbase-base
	docker_build hadoop-hbase-master
	docker_build hadoop-hbase-slave
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
