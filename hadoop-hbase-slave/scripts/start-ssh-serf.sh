#!/bin/bash

# start sshd
echo "start sshd..."
service ssh start

# start sef
echo -e "\nstart serf..." 
/appli/bin/start-serf-agent.sh > serf_log &

sleep 5

serf members

echo -e "\nhadoop-hbase-cluster-docker"