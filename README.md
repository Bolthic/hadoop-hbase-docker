# hadoop-hbase-docker

Quickly build arbitrary size Hadoop cluster based on Docker. Includes HBase database system

---

Core of this project is based on [krejcmat/hadoop-hbase-docker](https://github.com/krejcmat/hadoop-hbase-docker).

Usefull resources:

- Adaltas: [HowTo build hadoop/hbase](https://www.adaltas.com/fr/2020/12/18/big-data-open-source-distribution/)

## TODO

- wip: use TOSIT images
- done: compile hadoop && hbase from source
- done: starting hadoop and hbase

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

##### a) Download from Docker hub

```shell
$ docker pull bolthic/hadoop-hbase-master:latest
$ docker pull bolthic/hadoop-hbase-slave:latest
```

##### b)Build from sources(Dockerfiles)

The first argument of the script for builds is must be folder with Dockerfile or **all**. Tag for sources is **latest**

```shell
$ ./build-image.sh all
```

##### Check images

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

##### c) Run Hadoop cluster

###### Creating configures file for Hadoop and Hbase(includes zookeeper)

``` shell
$ configure-members.sh
Adding 172.17.0.4 slave2.bolthic.com to /etc/hosts
Adding 172.17.0.3 slave1.bolthic.com to /etc/hosts
master.bolthic.com
slaves           100%   57   102.0KB/s   00:00
slaves           100%   57    85.1KB/s   00:00
slaves           100%   57    93.9KB/s   00:00
hbase-site.xml   100% 1765     3.0MB/s   00:00
slave2.bolthic.com
Adding 172.17.0.2 master.bolthic.com to /etc/hosts
Adding 172.17.0.3 slave1.bolthic.com to /etc/hosts
slaves          100%   57   107.4KB/s   00:00
slaves          100%   57   138.7KB/s   00:00
slaves          100%   57   101.3KB/s   00:00
hbase-site.xml  100% 1765     2.7MB/s   00:00
slave1.bolthic.com
Adding 172.17.0.4 slave2.bolthic.com to /etc/hosts
Adding 172.17.0.2 master.bolthic.com to /etc/hosts
slaves          100%   57    83.8KB/s   00:00
slaves          100%   57    81.6KB/s   00:00
slaves          100%   57    94.3KB/s   00:00
hbase-site.xml  100% 1765     2.3MB/s   00:00

```

###### Starting Hadoop

``` shell
$ start-hadoop.sh
Starting namenodes on [master.bolthic.com]
Starting datanodes
Starting secondary namenodes [master.bolthic.com]
2022-12-16 10:14:44,124 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable


Starting resourcemanager
Starting nodemanagers

```

###### Testing Hadoop

Computing PI

``` shell
hadoop jar /appli/var/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 10 100
```

Counting words

``` shell
echo "can you can a can as a canner can can a can" | hadoop fs -put - /tmp/hdfs-example-input
hadoop jar /appli/var/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar grep /tmp/hdfs-example-input /tmp/hdfs-example-output 'c[a-z]+'
hadoop fs -cat /tmp/hdfs-example-output/part-r-00000
```

#### 5] Initialize Hbase database and run Hbase shell

##### Start HBase

``` shell
$ ./start-hbase.sh
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/appli/var/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/appli/var/hbase/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Reload4jLoggerFactory]
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/appli/var/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/appli/var/hbase/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Reload4jLoggerFactory]
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.apache.hadoop.hbase.unsafe.HBasePlatformDependent (file:/appli/var/hbase/lib/hbase-unsafe-4.1.2.jar) to method java.nio.Bits.unaligned()
WARNING: Please consider reporting this to the maintainers of org.apache.hadoop.hbase.unsafe.HBasePlatformDependent
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
slave2.bolthic.com: running zookeeper, logging to /appli/var/hbase/logs/hbase-root-zookeeper-slave2.bolthic.com.out
master.bolthic.com: running zookeeper, logging to /appli/var/hbase/logs/hbase-root-zookeeper-master.bolthic.com.out
slave1.bolthic.com: running zookeeper, logging to /appli/var/hbase/logs/hbase-root-zookeeper-slave1.bolthic.com.out
slave1.bolthic.com: SLF4J: Class path contains multiple SLF4J bindings.
slave1.bolthic.com: SLF4J: Found binding in [jar:file:/appli/var/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
slave1.bolthic.com: SLF4J: Found binding in [jar:file:/appli/var/hbase/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
slave1.bolthic.com: SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
master.bolthic.com: SLF4J: Class path contains multiple SLF4J bindings.
master.bolthic.com: SLF4J: Found binding in [jar:file:/appli/var/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
master.bolthic.com: SLF4J: Found binding in [jar:file:/appli/var/hbase/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
master.bolthic.com: SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
slave2.bolthic.com: SLF4J: Class path contains multiple SLF4J bindings.
slave2.bolthic.com: SLF4J: Found binding in [jar:file:/appli/var/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
slave2.bolthic.com: SLF4J: Found binding in [jar:file:/appli/var/hbase/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
slave2.bolthic.com: SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
running master, logging to /appli/var/hbase/logs/hbase--master-master.bolthic.com.out
master.bolthic.com: running regionserver, logging to /appli/var/hbase/logs/hbase-root-regionserver-master.bolthic.com.out
slave1.bolthic.com: running regionserver, logging to /appli/var/hbase/logs/hbase-root-regionserver-slave1.bolthic.com.out
slave2.bolthic.com: running regionserver, logging to /appli/var/hbase/logs/hbase-root-regionserver-slave2.bolthic.com.out
root@master:~# cat /appli/var/hbase/logs/hbase-root-regionserver-slave2.bolthic.com.out
cat: /appli/var/hbase/logs/hbase-root-regionserver-slave2.bolthic.com.out: No such file or directory
root@master:~# 

```

##### Start HBase shell

``` shell
$ hbase shell
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/appli/var/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/appli/var/hbase/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Reload4jLoggerFactory]
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.apache.hadoop.hbase.unsafe.HBasePlatformDependent (file:/appli/var/hbase/lib/hbase-unsafe-4.1.2.jar) to method java.nio.Bits.unaligned()
WARNING: Please consider reporting this to the maintainers of org.apache.hadoop.hbase.unsafe.HBasePlatformDependent
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
2022-12-16 10:27:32,073 WARN  [main] util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
HBase Shell
Use "help" to get list of supported commands.
Use "exit" to quit this interactive shell.
For Reference, please visit: http://hbase.apache.org/2.0/book.html#shell
Version 2.4.15-hadoop-3.3.4, rUnknown, Fri Nov 25 14:39:56 UTC 2022
Took 0.0015 seconds
hbase:001:0>
```

##### Check status

``` shell
hbase:001:0> status
1 active master, 0 backup masters, 3 servers, 0 dead, 0.6667 average load
Took 0.3261 seconds
hbase:002:0>
```

##### Example of creating table and adding some values

``` shell
create 'album','label','image'
```

Now you have a table called album, with a label, and an image family. These families are “static” like the columns in the RDBMS world.

Add some data:

``` shell
put 'album','label1','label:size','10'
put 'album','label1','label:color','255:255:255'
put 'album','label1','label:text','Family album'
put 'album','label1','image:name','holiday'
put 'album','label1','image:source','/tmp/pic1.jpg'
```

Print table album,label1.

``` shell
get 'album','label1'

COLUMN                                              CELL
image:name                                          timestamp=1454590694743, value=holiday
image:source                                        timestamp=1454590759183, value=/tmp/pic1.jpg
label:color                                         timestamp=1454590554725, value=255:255:255
label:size                                          timestamp=1454590535642, value=10
label:text                                          timestamp=1454590583786, value=Family album
6 row(s) in 0.0320 seconds
```

#### 6] Control cluster from web UI

##### Overview of UI web ports

| web ui            | port       |  mapped host port              |
| ----------------  |:----------:|:------------------------------:|
| NameNode          | 9870       | [8000](http://localhost:8000/) |
| SecondaryNameNode | 9868       | [8001](http://localhost:8000/) |
| ResourceManager   | 8088       | [8010](http://localhost:8010/) |
| Hbase master      | 60010      | [8020](http://localhost:8020/) |
| Datanode          | 9864       | [81xx](http://localhost;8100/) |
| Nodemanager       | 8042       | [82xx](http://localhost:82xx/) |
| Regionserver      | 16030      | [83xx](http://localhost:83xx/) |

xx: 00 for master, 01 for slave1, 02 for slave2....

#### 7] Stopping HBase and Hadoop

``` shell
$ stop-hbase.sh
...
$ stop-hadoop.sh
...
```

### Hadoop usaga


### HBase usage
[python wrapper for HBase rest API](http://blog.cloudera.com/blog/2013/10/hello-starbase-a-python-wrapper-for-the-hbase-rest-api/)

[usage of Java API for Hbase](https://autofei.wordpress.com/2012/04/02/java-example-code-using-hbase-data-model-operations/)

[Hbase shell commands](https://learnhbase.wordpress.com/2013/03/02/hbase-shell-commands/)


