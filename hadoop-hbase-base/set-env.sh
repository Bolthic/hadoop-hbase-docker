export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 
export HADOOP_INSTALL=/appli/var/hadoop
export HADOOP_HOME=$HADOOP_INSTALL 
export PATH=$PATH:$HADOOP_INSTALL/bin  
export PATH=$PATH:$HADOOP_INSTALL/sbin  
export HADOOP_MAPRED_HOME=$HADOOP_INSTALL  
export HADOOP_COMMON_HOME=$HADOOP_INSTALL  
export HADOOP_HDFS_HOME=$HADOOP_INSTALL
export HDFS_NAMENODE_USER=bolthic
export HDFS_DATANODE_USER=bolthic
export HDFS_SECONDARYNAMENODE_USER=bolthic
export HADOOP_CONF_DIR=$HADOOP_INSTALL/etc/hadoop   
export YARN_HOME=$HADOOP_INSTALL
#export YARN_CONF_DIR=$HADOOP_INSTALL/etc/hadoop
export YARN_RESOURCEMANAGER_USER=bolthic
export YARN_NODEMANAGER_USER=bolthic

export HBASE_INSTALL=/appli/var/hbase
export HBASE_HOME=$HBASE_INSTALL 
export PATH=$PATH:$HBASE_INSTALL/bin

export PATH=$PATH:/appli/bin:$JAVA_HOME/bin