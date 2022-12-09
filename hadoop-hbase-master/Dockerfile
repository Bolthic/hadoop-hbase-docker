FROM bolthic/hadoop-hbase-base:latest
LABEL org.opencontainers.image.authors="niiboltoh3@protonmail.com"
LABEL version="1.0"
LABEL description="Image du master"

# Master hadoop: NameNode, ResourceManager, DataNode, NodeManager, Zookeeper
# Master hbase: HMaster, RegionServer
ENV HADOOP_INSTALL /appli/var/hadoop
ENV HBASE_INSTALL /appli/var/hbase

# Configuring hadoop master
RUN mkdir -p /appli_data/zookeeper && \
    mkdir -p /appli_data/hdfs/namenode && \ 
    mkdir -p /appli_data/hdfs/datanode && \
    mkdir -p /appli/var/hadoop/logs
RUN chown bolthic:bolthic /appli_data/zookeeper /appli_data/hdfs/namenode /appli_data/hdfs/datanode /appli/var/hadoop/logs



ADD conf/hadoop/hdfs-site.xml $HADOOP_INSTALL/etc/hadoop/hdfs-site.xml 
ADD conf/hadoop/core-site.xml $HADOOP_INSTALL/etc/hadoop/core-site.xml
ADD conf/hadoop/mapred-site.xml $HADOOP_INSTALL/etc/hadoop/mapred-site.xml
ADD conf/hadoop/yarn-site.xml $HADOOP_INSTALL/etc/hadoop/yarn-site.xml
ADD scripts/stop-hadoop.sh /appli/bin/stop-hadoop.sh
ADD scripts/start-hadoop.sh /appli/bin/start-hadoop.sh
ADD scripts/run-wordcount.sh /appli/bin/run-wordcount.sh
ADD scripts/configure-members.sh /appli/bin/configure-members.sh
ADD scripts/configure-slave.sh /appli/bin/configure-slave.sh
RUN chmod 0755 /appli/bin/stop-hadoop.sh /appli/bin/start-hadoop.sh /appli/bin/run-wordcount.sh /appli/bin/configure-members.sh /appli/bin/configure-slave.sh

# Configuring hbase master
ADD conf/hbase/hbase-site.xml $HBASE_INSTALL/conf/hbase-site.xml
ADD scripts/stop-hbase.sh /appli/bin/stop-hbase.sh
ADD scripts/start-hbase.sh /appli/bin/start-hbase.sh
RUN chmod 0755 /appli/bin/stop-hbase.sh /appli/bin/start-hbase.sh

# configuring docker entry points
ADD conf/slaves /appli/etc/slaves
ADD scripts/start-ssh-serf.sh /appli/bin/start-ssh-serf.sh
ADD docker-entrypoint.sh /appli/bin/docker-entrypoint.sh
RUN chmod 0755 /appli/bin/start-ssh-serf.sh /appli/bin/docker-entrypoint.sh
RUN chmod 1777 tmp

# format namenode
RUN sudo -u bolthic -i $HADOOP_INSTALL/bin/hdfs namenode -format

EXPOSE 22 7373 7946 9000 50010 50020 50070 50075 50090 50475 8030 8031 8032 8033 8040 8042 8060 8088 9868 9870 9864 9866 9867 50060

CMD '/appli/bin/start-ssh-serf.sh'; 'bash'