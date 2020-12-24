#!/bin/bash

if [[ -z "$KAFKA_CREATE_TOPICS" ]]; then
    exit 0
fi

#---------------- ZK Cluster check----------------------#
echo "Validating ZK Cluster ...."
zk_cluster_status=0
ZK_COUNT=$(echo $KAFKA_ZOOKEEPER_CONNECT | tr ',' ' ' | wc -w)
echo "ZK_COUNT: $ZK_COUNT"
while [[ $zk_cluster_status -eq 0 ]]
do
  if [[ "$ZK_COUNT" -eq "3" ]]; then
    echo "ZK cluster setup...."
    zk_cluster1=$(echo stat | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1) 2181 |awk '/Mode: follower|Mode: leader/' |wc -l )
    zk_cluster2=$(echo stat | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 2|cut -d ":" -f1) 2181 |awk '/Mode: follower|Mode: leader/' |wc -l )
    zk_cluster3=$(echo stat | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 3|cut -d ":" -f1) 2181 |awk '/Mode: follower|Mode: leader/' |wc -l )
      if [[ "$zk_cluster1" -eq "1" ]] && [[ "$zk_cluster2" -eq "1" ]] && [[ "$zk_cluster3" -eq "1" ]] ; then
        echo $(date): Healthy zk Cluster
        break
      else
        echo $(date): Un-Healthy zk Cluster.. Retrying...........
        zk_cluster_status=0
      sleep 5
      fi
  else
    echo "Non cluster ZK setup...."
    zk_cluster1=$(echo stat | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1) 2181 |awk '/Mode: standalone/' |wc -l )
      if [[ "$zk_cluster1" -eq "1" ]] ; then
        echo $(date): Healthy zk instance
        break
      else
        echo $(date): Un-Healthy zk instance.. Retrying...........
        zk_cluster_status=0
      sleep 5
      fi
  fi
done

#---------------- Kafka Cluster check-------------------#
echo "Validating Kafka Cluster ...."

kafka_cluster_status=0
while [[ $kafka_cluster_status -eq 0 ]]
do
  if [[ "$ZK_COUNT" -eq "3" ]]; then
    echo "Kafka cluster setup...."
    kafka_cluster1=$(echo dump | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1) 2181 | grep brokers |wc -l )
    kafka_cluster2=$(echo dump | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 2|cut -d ":" -f1) 2181 | grep brokers |wc -l )
    kafka_cluster3=$(echo dump | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 3|cut -d ":" -f1) 2181 | grep brokers |wc -l )
      if [[ "$kafka_cluster1" -eq "3" ]] && [[ "$kafka_cluster2" -eq "3" ]] && [[ "$kafka_cluster3" -eq "3" ]] ; then
        echo $(date): Healthy kafka Cluster
        break
      else
       echo $(date): Un-Healthy kafka Cluster.. Retrying...........
       kafka_cluster_status=0
     sleep 5
     fi
  else
    echo "Non cluster kafka setup......"
    kafka_cluster1=$(echo dump | nc $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1) 2181 | grep brokers |wc -l )
      if [[ "$kafka_cluster1" -eq "1" ]] ; then
        echo $(date): Healthy kafka instance
        break
      else
        echo $(date): Un-Healthy kafka instance.. Retrying...........
        kafka_cluster_status=0
        sleep 5
     fi
  fi
done


if [[ -z "$START_TIMEOUT" ]]; then
    START_TIMEOUT=600
fi
export KAFKA_HEAP_OPTS="-Xmx256M -Xms128M"
start_timeout_exceeded=false
count=0
step=10
while netstat -lnt | awk '$4 ~ /:'"$KAFKA_PORT"'$/ {exit 1}'; do
    echo "waiting for kafka to be ready"
    sleep $step;
    count=$((count + step))
    if [ $count -gt $START_TIMEOUT ]; then
        start_timeout_exceeded=true
        break
    fi
done

if $start_timeout_exceeded; then
    echo "Not able to auto-create topic (waited for $START_TIMEOUT sec)"
    exit 1
fi

# introduced in 0.10. In earlier versions, this will fail because the topic already exists.
# shellcheck disable=SC1091
source "/usr/bin/versions.sh"
if [[ "$MAJOR_VERSION" == "0" && "$MINOR_VERSION" -gt "9" ]] || [[ "$MAJOR_VERSION" -gt "0" ]]; then
    KAFKA_0_10_OPTS="--if-not-exists"
fi

# Expected format:
#   name:partitions:replicas:cleanup.policy
IFS="${KAFKA_CREATE_TOPICS_SEPARATOR-,}"; for topicToCreate in $KAFKA_CREATE_TOPICS; do
    echo "creating topics: $topicToCreate"
    IFS=':' read -r -a topicConfig <<< "$topicToCreate"
    config=
    if [ -n "${topicConfig[3]}" ]; then
        config="--config=retention.ms=${topicConfig[3]}"
    fi

    COMMAND="JMX_PORT='' ${KAFKA_HOME}/bin/kafka-topics.sh \\
                --create \\
                --zookeeper ${KAFKA_ZOOKEEPER_CONNECT} \\
                --topic ${topicConfig[0]} \\
                --partitions ${topicConfig[1]} \\
                --replication-factor ${topicConfig[2]} \\
                ${config} \\
                ${KAFKA_0_10_OPTS} &"
    eval "${COMMAND}"
wait
done

sleep 30
#---------------- Replication factor  check-------------------#
echo "Validating replication factor...."
brokerids="0,1,2"
IFS="${KAFKA_CREATE_TOPICS_SEPARATOR-,}"; for topicToCreate in $KAFKA_CREATE_TOPICS; do
    IFS=':' read -r -a topicConfig <<< "$topicToCreate"
    sep=","
    replica=$(/opt/kafka/bin/kafka-topics.sh --describe --zookeeper $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1):2181 --topic ${topicConfig[0]} | head -1|awk '{print $3}'|cut -d ":" -f 2)
    if [ -z "$replica" ]
    then
      replica=0
    fi
    echo "Topic: ${topicConfig[0]}, Configured :$replica, Actual:${topicConfig[2]}"
    replica_status=0
    if [ $HOSTNAME == "kafka-0" ] && [ $replica -lt "${topicConfig[2]}" ]; then
    replica_status=0
        while [[ $replica_status -eq 0 ]]
           do
            echo "Mismatch in Replication factor for Topic: ${topicConfig[0]}. Updating...."
            echo '{"version":1,
                 "partitions":[' > /opt/kafka/tmp.json
            pcount=$((${topicConfig[1]} - 1))
            while [[ $pcount -ge 0 ]]
                        do
                if [ $pcount -eq 0 ]; then sep=""; fi
                   randombrokers=$(echo "$brokerids" | sed -r 's/,/ /g' | tr " " "\n" | shuf | tr  "\n" "," | head -c -1)
                   echo "    {\"topic\":\"${topicConfig[0]}\",\"partition\":${pcount},\"replicas\":[${randombrokers}]}$sep" >>/opt/kafka/tmp.json
                   pcount=$(($pcount-1))
            done
            echo '  ]
            }' >>/opt/kafka/tmp.json
            cat /opt/kafka/tmp.json
            /opt/kafka/bin/kafka-reassign-partitions.sh --zookeeper $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1):2181 --reassignment-json-file /opt/kafka/tmp.json --execute
        sleep 30
        replica=`/opt/kafka/bin/kafka-topics.sh --describe --zookeeper $(echo $KAFKA_ZOOKEEPER_CONNECT|cut -d "," -f 1|cut -d ":" -f1):2181 --topic ${topicConfig[0]} | head -1|awk '{print $3}'|cut -d ":" -f 2`
        if [ -z "$replica" ]
        then
          replica=0
        fi
        if [ $replica -lt "${topicConfig[2]}" ]; then
            replica_status=0
            echo "Post replication update: Topic: ${topicConfig[0]}, Configured :$replica, Actual:${topicConfig[2]}"
        else
            replica_status=1
            echo "Post replication update: Topic: ${topicConfig[0]}, Configured :$replica, Actual:${topicConfig[2]}"
        fi
      done
  fi
done
exit
