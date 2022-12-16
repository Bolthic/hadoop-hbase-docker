FROM debian:bullseye-slim
LABEL org.opencontainers.image.authors="niiboltoh3@protonmail.com"
LABEL version="1.0"
LABEL description="Image de base"
ARG hadoop
ARG hbase
ENV HADOOP_DISTRO=$hadoop
ENV HBASE_DISTRO=$hbase 
ENV DEBIAN_FRONTEND=noninteractive

#removing unnecessary
# RUN cp -R /usr/share/locale/en* /tmp/ && rm -rf /usr/share/locale/* && mv /tmp/en* /usr/share/locale/ 
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2

# updating system
RUN sed -i "s/ main/ main contrib/g" /etc/apt/sources.list
RUN apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y
RUN apt-get update && apt-get upgrade -y && apt-get -y --no-install-recommends install unzip dnsmasq wget curl openssh-server vim net-tools iproute2 dnsutils sudo

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-11-jre
# RUN apt-get update && apt-get install -y --no-install-recommends openjdk-11-jdk
RUN apt-get update && apt-get install -y --no-install-recommends python python3

RUN rm -rf /var/cache/debconf/*-old && rm -rf /var/lib/apt/lists/* && rm -rf /usr/share/doc/* 

#message
RUN echo "`cat /etc/issue.net` Docker Image - Bolthic/bullseye-slim - `date +'%Y/%m/%d'`" > /etc/motd

# our install structure
RUN mkdir -p /appli_data
RUN mkdir -p /appli/bin
RUN mkdir -p /appli/var
RUN mkdir -p /appli/etc
RUN mkdir -p /appli/local

# dnsmasq configuration
ADD dnsmasq/* /etc/

# install serf
RUN wget -q -o out.log -P /tmp/ https://releases.hashicorp.com/serf/0.8.2/serf_0.8.2_linux_amd64.zip && rm -rf /appli/bin/serf
RUN unzip /tmp/serf_0.8.2_linux_amd64.zip -d /appli/bin && rm /tmp/serf_0.8.2_linux_amd64.zip

# configure serf
ENV SERF_CONFIG_DIR /appli/etc/serf
ADD serf/* $SERF_CONFIG_DIR/
ADD handlers $SERF_CONFIG_DIR/handlers
RUN chmod +x $SERF_CONFIG_DIR/event-router.sh $SERF_CONFIG_DIR/start-serf-agent.sh
RUN ln -s $SERF_CONFIG_DIR/start-serf-agent.sh /appli/bin/start-serf-agent.sh

#JAVA
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

#configure ssh free key access
ADD ssh_config /appli/local/
RUN mkdir /var/run/sshd && \
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
cp /appli/local/ssh_config ~/.ssh/config && \
sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

#install hadoop 
ADD dist/hadoop-${HADOOP_DISTRO}.tar.gz /appli/var/
RUN mv /appli/var/hadoop-${HADOOP_DISTRO} /appli/var/hadoop

ADD dist/hbase-${HBASE_DISTRO}-bin.tar.gz /appli/var/
RUN mv /appli/var/hbase-${HBASE_DISTRO} /appli/var/hbase

ADD set-env.sh /appli/etc/set-env.sh
ADD bashrc /appli/local/
RUN cp /appli/local/bashrc ~/.bashrc
RUN chmod 0755 ~/.bashrc /appli/etc/set-env.sh

RUN useradd -ms /bin/bash bolthic
RUN mkdir -p /home/bolthic/.ssh && \
ssh-keygen -t rsa -f /home/bolthic/.ssh/id_rsa -P '' && \
cat /home/bolthic/.ssh/id_rsa.pub >> /home/bolthic/.ssh/authorized_keys && \
cp /appli/local/ssh_config /home/bolthic/.ssh/config
RUN cp /appli/local/bashrc /home/bolthic/.bashrc
RUN chmod 0755 /home/bolthic/.bashrc
RUN chown -R bolthic:bolthic /home/bolthic/.ssh /home/bolthic/.bashrc
