#!/bin/bash

function init_members(){
    members=$(serf members 2>&1| tac)
    while read -r line; do
        if [[ $line =~ "alive" ]]
            then
                alive_mem=$(echo $line | cut -d " " -f 1 2>&1) #get hosts
                alive_ip=$(echo $line | cut -d " " -f 2 | cut -d ":" -f 1 2>&1) # get ip 
                if ! grep -q "$alive_ip" /etc/hosts; then
                    echo "Adding $alive_ip $alive_mem to /etc/hosts"
                    echo "$alive_ip      $alive_mem" >> /etc/hosts
                fi
                continue
        fi
    done <<< "$members"
}

init_members
