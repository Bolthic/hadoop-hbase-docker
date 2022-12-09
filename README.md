# hadoop-hbase-docker

Quickly build arbitrary size Hadoop cluster based on Docker. Includes HBase database system

---

Core of this project is based on [krejcmat/hadoop-hbase-docker](https://github.com/krejcmat/hadoop-hbase-docker).

Usefull resources:

- Adaltas: [HowTo build hadoop/hbase](https://www.adaltas.com/fr/2020/12/18/big-data-open-source-distribution/)

## TODO

- wip: building docker image
- wip: use TOSIT images
- done: compile hadoop && hbase from source

## Version of products

| system          | version      |
| ----------------|:------------:|
| Hadoop          | 3.3.4        |
| HBase           | 2.4.15       |

Used versions of Hadoop and HBase are configurable, they are not fully tested. Go and see [Tosit/TDP](https://github.com/TOSIT-IO) for a fully tested compatibility.

### Usage

#### 1] Clone git repository

```shell
$ git clone https://github.com/bolthic/hadoop-hbase-docker.git
$ cd hadoop-hbase-docker
```

#### 2] Getting hadoop and hbase distribution files

if you need other versions, modify HADOOP_VERSION and HBASE_VERSION. Additionnal configuration may be needed in hadoop and hbase sub directory

```shell
$ build_hadoop.sh
$ build_habase.sh
```

#### 3] Get docker images

Two options how to get images are available. By pulling images directly from Docker official repository or build from Dockerfiles and sources files(see Dockerfile in each hadoop-hbase-* directory). Builds on DockerHub are automatically created by pull trigger or GitHub trigger after update Dockerfiles. Triggers are setuped for tag:latest. Below is example of stable version bolthic/hadoop-hbase-<>:0.1. Version bolthic/hadoop-hbase-<>:latest is compiled on DockerHub from master branche on GitHub.

###### a) Download from Docker hub

```shell
$ docker pull bolthic/hadoop-hbase-master:latest
$ docker pull bolthic/hadoop-hbase-slave:latest
```

###### b)Build from sources(Dockerfiles)

The first argument of the script for builds is must be folder with Dockerfile or **all**. Tag for sources is **latest**

```shell
$ ./build-image.sh all
```

###### Check images

``` shell
$ docker images

bolthic/hadoop-hbase-master   latest     c78d798e9d19   2 seconds ago   2.81GB
bolthic/hadoop-hbase-slave    latest     099ff00f2c16   6 minutes ago   2.81GB
bolthic/hadoop-hbase-base     latest     8e88787dca7a   6 minutes ago   2.81GB

```

#### 4] Initialize Hadoop (master and slaves)

##### a) run containers

The first parameter of start-container.sh script is tag of image version, second parameter configuring number of nodes.

``` shell
$ ./start-container.sh latest 2

start master container...
start slave1 container...
start slave2 container...
```

##### b) Check status

Check members of cluster

```shell
$ serf members

master.bolthic.com  172.17.0.2:7946  alive  
slave1.bolthic.com  172.17.0.3:7946  alive
slave2.bolthic.com  172.17.0.4:7946  alive
```

##### b) Run Hadoop cluster

###### Creating configures file for Hadoop and Hbase(includes zookeeper)

``` shell
$ cd ~
$ ./configure-members.sh


```

###### Starting Hadoop

```
$ ./start-hadoop.sh 
 #For stop Hadoop ./stop-hadoop.sh

Starting namenodes on [master.krejcmat.com]
master.krejcmat.com: Warning: Permanently added 'master.krejcmat.com,172.17.0.2' (ECDSA) to the list of known hosts.
master.krejcmat.com: starting namenode, logging to /usr/local/hadoop/logs/hadoop-root-namenode-master.krejcmat.com.out
slave1.krejcmat.com: Warning: Permanently added 'slave1.krejcmat.com,172.17.0.3' (ECDSA) to the list of known hosts.
master.krejcmat.com: Warning: Permanently added 'master.krejcmat.com,172.17.0.2' (ECDSA) to the list of known hosts.
slave1.krejcmat.com: starting datanode, logging to /usr/local/hadoop/logs/hadoop-root-datanode-slave1.krejcmat.com.out
master.krejcmat.com: starting datanode, logging to /usr/local/hadoop/logs/hadoop-root-datanode-master.krejcmat.com.out
Starting secondary namenodes [0.0.0.0]
0.0.0.0: Warning: Permanently added '0.0.0.0' (ECDSA) to the list of known hosts.
0.0.0.0: starting secondarynamenode, logging to /usr/local/hadoop/logs/hadoop-root-secondarynamenode-master.krejcmat.com.out

starting yarn daemons
starting resource manager, logging to /usr/local/hadoop/logs/yarn--resourcemanager-master.krejcmat.com.out
master.krejcmat.com: Warning: Permanently added 'master.krejcmat.com,172.17.0.2' (ECDSA) to the list of known hosts.
slave1.krejcmat.com: Warning: Permanently added 'slave1.krejcmat.com,172.17.0.3' (ECDSA) to the list of known hosts.
slave1.krejcmat.com: starting nodemanager, logging to /usr/local/hadoop/logs/yarn-root-nodemanager-slave1.krejcmat.com.out
master.krejcmat.com: starting nodemanager, logging to /usr/local/hadoop/logs/yarn-root-nodemanager-master.krejcmat.com.out
```



#### 4] Initialize Hbase database and run Hbase shell
######Start HBase
```
$ cd ~
$ ./start-hbase.sh

(hbase(main):001:0>)
```

###### Check status
```
(hbase(main):001:0>)$ status

2 servers, 0 dead, 1.0000 average load
```
###### Example of creating table and adding some values
```
$ create 'album','label','image'
```
Now you have a table called album, with a label, and an image family. These families are “static” like the columns in the RDBMS world.

Add some data:
```
$ put 'album','label1','label:size','10'
$ put 'album','label1','label:color','255:255:255'
$ put 'album','label1','label:text','Family album'
$ put 'album','label1','image:name','holiday'
$ put 'album','label1','image:source','/tmp/pic1.jpg'
```

Print table album,label1.
```
$get 'album','label1'

COLUMN                                              CELL
image:name                                          timestamp=1454590694743, value=holiday
image:source                                        timestamp=1454590759183, value=/tmp/pic1.jpg
label:color                                         timestamp=1454590554725, value=255:255:255
label:size                                          timestamp=1454590535642, value=10
label:text                                          timestamp=1454590583786, value=Family album
6 row(s) in 0.0320 seconds
```

####5] Control cluster from web UI
######Overview of UI web ports
| web ui           | port       |
| ---------------- |:----------:| 
| Hbase            | 60010      |


######Access from parent computer of docker container
Check IP addres in master container
```
$ ip a

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:2/64 scope link 
       valid_lft forever preferred_lft forever

```
so your IP address is 172.17.0.2

```
$ xdg-open http://172.17.0.2:60010/
```
######Direct access from container(not implemented)
Used Linux distribution is installed without graphical UI. Easiest way is to use another Unix distribution by modifying Dockerfile of hadoop-hbase-dnsmasq and rebuild images. In this case start-container.sh script must be modified. On the line where the master container is created must add parameters for [X forwarding](http://wiki.ros.org/docker/Tutorials/GUI). 


######HBase usage
[python wrapper for HBase rest API](http://blog.cloudera.com/blog/2013/10/hello-starbase-a-python-wrapper-for-the-hbase-rest-api/)

[usage of Java API for Hbase](https://autofei.wordpress.com/2012/04/02/java-example-code-using-hbase-data-model-operations/)

[Hbase shell commands](https://learnhbase.wordpress.com/2013/03/02/hbase-shell-commands/)


