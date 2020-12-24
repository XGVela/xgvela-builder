#!/bin/bash

hostip=`hostname -i`
hostname=`hostname -s`
hostdomain=`hostname -d`

echo Hostname:`hostname`, IpAddress:$hostip

ORIG_IFS=$IFS

# Check for $ETCD_NAME
if [ -z ${ETCD_NAME+x} ]; then
        ETCD_NAME="etcd0"
        echo "Using default NAME ($ETCD_NAME)"
else
        echo "Detected new NAME value of $ETCD_NAME"
fi

# Check for $ETCD_CLIENT_URLS
if [ -z ${ETCD_CLIENT_URLS+x} ]; then
        ETCD_CLIENT_URLS="http://0.0.0.0:2379"
        echo "Using default CLIENT_URLS ($ETCD_CLIENT_URLS)"
else
        echo "Detected new CLIENT_URLS value of $ETCD_CLIENT_URLS"
fi

# Check for $ETCD_PEER_URLS
if [ -z ${ETCD_PEER_URLS+x} ]; then
        ETCD_PEER_URLS="http://0.0.0.0:2380"
        echo "Using default PEER_URLS ($ETCD_PEER_URLS)"
else
        echo "Detected new PEER_URLS value of $ETCD_PEER_URLS"
fi

# Check for $ETCD_ADVERTISE_CLIENT_URLS
if [ -z ${ETCD_ADVERTISE_CLIENT_URLS+x} ]; then
        ETCD_ADVERTISE_CLIENT_URLS="http://$hostip:2379"
        echo "Using default ADVERTISE_CLIENT_URLS ($ETCD_ADVERTISE_CLIENT_URLS)"
else
        echo "Detected new ADVERTISE_CLIENT_URLS value of $ETCD_ADVERTISE_CLIENT_URLS"
fi

# Check for $ETCD_INITIAL_ADVERTISE_PEER_URLS
if [ -z ${ETCD_INITIAL_ADVERTISE_PEER_URLS+x} ]; then
        ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$hostip:2380"
        echo "Using default INITIAL_ADVERTISE_PEER_URLS ($ETCD_INITIAL_ADVERTISE_PEER_URLS)"
else
        echo "Detected new INITIAL_ADVERTISE_PEER_URLS value of $ETCD_INITIAL_ADVERTISE_PEER_URLS"
fi

# Check for $ETCD_INITIAL_CLUSTER_TOKEN
if [ -z ${ETCD_INITIAL_CLUSTER_TOKEN+x} ]; then
        ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-1"
        echo "Using default INITIAL_CLUSTER_TOKEN ($ETCD_INITIAL_CLUSTER_TOKEN)"
else
        echo "Detected new INITIAL_CLUSTER_TOKEN value of $ETCD_INITIAL_CLUSTER_TOKEN"
fi

# Check for $ETCD_INITIAL_CLUSTER
if [ -z ${ETCD_INITIAL_CLUSTER+x} ]; then
        ETCD_INITIAL_CLUSTER=$ETCD_NAME"=http://$hostip:2380"
        echo "Using default INITIAL_CLUSTER ($ETCD_INITIAL_CLUSTER)"
else
        echo "Detected new INITIAL_CLUSTER value of $ETCD_INITIAL_CLUSTER"
fi

if [[ -n "$HOST_NAME_COMMAND" ]]; then
    HOST_NAME_VALUE=$(eval "$HOST_NAME_COMMAND")

    # Replace any occurences of _{HOST_NAME_COMMAND} with the value
    IFS=$'\n'
    for VAR in $(env); do
        if [[ $VAR =~ ^ETCD_ && "$VAR" =~ "_{HOST_NAME_COMMAND}" ]]; then
            echo "export ${VAR//_\{HOST_NAME_COMMAND\}/$HOST_NAME_VALUE}"
            eval "export ${VAR//_\{HOST_NAME_COMMAND\}/$HOST_NAME_VALUE}"
        fi
    done
    IFS=$ORIG_IFS
fi
if [[ -n "$HOST_IP_COMMAND" ]]; then
    HOST_IP_VALUE=$(eval "$HOST_IP_COMMAND")

    # Replace any occurences of _{HOST_IP_COMMAND} with the value
    IFS=$'\n'
    for VAR in $(env); do
        if [[ $VAR =~ ^ETCD_ && "$VAR" =~ "_{HOST_IP_COMMAND}" ]]; then
            echo "export ${VAR//_\{HOST_IP_COMMAND\}/$HOST_IP_VALUE}"
            eval "export ${VAR//_\{HOST_IP_COMMAND\}/$HOST_IP_VALUE}"
        fi
    done
    IFS=$ORIG_IFS
fi
if [[ -n "$HOST_DOMAIN_COMMAND" ]]; then
    HOST_DOMAIN_VALUE=$(eval "$HOST_DOMAIN_COMMAND")

    # Replace any occurences of _{HOST_DOMAIN_COMMAND} with the value
    IFS=$'\n'
    for VAR in $(env); do
        if [[ $VAR =~ ^ETCD_ && "$VAR" =~ "_{HOST_DOMAIN_COMMAND}" ]]; then
            echo "export ${VAR//_\{HOST_DOMAIN_COMMAND\}/$HOST_DOMAIN_VALUE}"
            eval "export ${VAR//_\{HOST_DOMAIN_COMMAND\}/$HOST_DOMAIN_VALUE}"
        fi
    done
    IFS=$ORIG_IFS
fi

mkdir -p /data/${ETCD_NAME}
chmod 700 /data/${ETCD_NAME}

ETCD_CMD="/bin/etcd \
        -data-dir /data/${ETCD_NAME} \
        -listen-client-urls ${ETCD_CLIENT_URLS} \
        -listen-peer-urls ${ETCD_PEER_URLS} $*"

echo -e "Running '$ETCD_CMD' \nBEGIN ETCD OUTPUT\n"

exec $ETCD_CMD
