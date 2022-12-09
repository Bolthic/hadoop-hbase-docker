#!/bin/bash

slaves=/appli/etc/slaves
rm -f $slaves
>$slaves
regionservers=/appli/var/hbase/conf/regionservers
rm -f $regionservers
>$regionservers
hbaseconf=/appli/var/hbase/conf/hbase-site.xml


function init_members(){
        touch ~/.ssh/known_hosts
        members=$(serf members 2>&1| tac)
        while read -r line; do
                if [[ $line =~ "alive" ]]
                then
                        alive_mem=$(echo $line | cut -d " " -f 1 2>&1) #get hosts
                        alive_ip=$(echo $line | cut -d " " -f 2 | cut -d ":" -f 1 2>&1) # get ip 
                        echo "$alive_mem">>$slaves
                        if ! grep -q "$alive_ip" /etc/hosts; then
                                echo "Adding $alive_ip $alive_mem to /etc/hosts"
                                echo "$alive_ip      $alive_mem" >> /etc/hosts
                        fi
                        for udir in ~ /home/bolthic
                        do
                                ssh-keygen -R "$alive_mem" -f  $udir/.ssh/known_hosts 2>>/dev/null
                                ssh-keygen -R "$alive_ip" -f  $udir/.ssh/known_hosts 2>>/dev/null
                                ssh-keyscan -H "$alive_ip" >> $udir/.ssh/known_hosts 2>>/dev/null
                                ssh-keyscan -H "$alive_mem" >> $udir/.ssh/known_hosts 2>>/dev/null
                        done
                        chown bolthic:bolthic /home/bolthic/.ssh/known_hosts
                        continue
                fi
        done <<< "$members"

        #copy slave file to all slaves and master
        #create hbase 
        members_line=$(paste -d, -s $slaves 2>&1)
        memstr='members' #uniq string for replace
        sed -i -e "s/$memstr/$members_line/g" $hbaseconf

        for member in `cat $slaves`; do
                echo $member
                ssh $member -C "/appli/bin/configure-slave.sh" #dnsmask
                scp $slaves $member:$HADOOP_CONF_DIR/slaves #hadoop 2
                scp $slaves $member:$HADOOP_CONF_DIR/workers #hadoop 3
                scp $slaves $member:$regionservers #hbase
                scp $hbaseconf $member:$hbaseconf #hbase
        done
}


init_members
