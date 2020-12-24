#! /bin/bash
export host='kafka-1'
export HOSTNAME_COMMAND='echo $host'
export KAFKA_ADVERTISED_LISTENERS='PLAINTEXT://${_{HOSTNAME_COMMAND}}.kafka-svc.default.svc.cluster.local:9092'

echo $HOSTNAME_COMMAND
echo $KAFKA_ADVERTISED_LISTENERS


if [[ -n "$HOSTNAME_COMMAND" ]]; then
    
    HOSTNAME_VALUE=$(eval "$HOSTNAME_COMMAND")

    # Replace any occurences of _{HOSTNAME_COMMAND} with the value
    IFS=$'\n'
    for VAR in $(env); do
        if [[ $VAR =~ ^KAFKA_ && "$VAR" =~ "_{HOSTNAME_COMMAND}" ]]; then
            echo ${VAR//_\{HOSTNAME_COMMAND\}/$HOSTNAME_VALUE}
            eval "export ${VAR//_\{HOSTNAME_COMMAND\}/$HOSTNAME_VALUE}"
        fi
    done
    IFS=$ORIG_IFS
fi

echo $HOSTNAME_COMMAND
echo $KAFKA_ADVERTISED_LISTENERS


