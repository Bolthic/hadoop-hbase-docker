FROM debian:bullseye
LABEL org.opencontainers.image.authors="niiboltoh3@protonmail.com"
LABEL version="1.0"
LABEL description="Image de base"   
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt-get install -y --no-install-recommends openjdk-11-jre
RUN java -version

RUN mkdir -p /appli_data
RUN mkdir -p /appli/var
RUN mkdir -p /appli/etc
RUN mkdir -p /appli/local

# move all configuration files into container
ADD files/* /appli/local/


#install hbase 
# RUN wget -q -o out.log -P /tmp http://www.eu.apache.org/dist/hbase/1.2.4/hbase-1.2.4-bin.tar.gz && \
# tar xzf /tmp/hbase-1.2.4-bin.tar.gz -C /usr/local && \
# rm /tmp/hbase-1.2.4-bin.tar.gz  && \
# mv /usr/local/hbase-1.2.4 /usr/local/hbase && \
# mv /usr/local/hbase-env.sh /usr/local/hbase/conf/hbase-env.sh  && \
# mv /usr/local/bashrc ~/.bashrc


# RUN rm -rf /appli/local