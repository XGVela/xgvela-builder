#!/bin/bash

K8S_HOSTID=docker-desktop
XGVELA_NS=xgvela
XGVELA_ID=xgvela
IMAGES_DIR=build/artifacts/images
CHARTS=build/artifacts/xgvela-0.1.tgz
DEPLOYMENT_YAML=deployment/xgvela_small.yaml

if [[ "$1" == "images" || "$1" == "all" ]];
then
    for file in $IMAGES_DIR/*.gz;
    do
        docker load < $file

        file_name=${file##*\/}
        version="v"${file_name##*'-v'}
        image_name=${file_name//-$version/}
        version=${version//".tar.gz"/}

        docker tag $image_name:$version localhost:5000/$image_name:$version

        docker push localhost:5000/$image_name:$version
    done
fi

if [[ "$1" == "install"  || "$1" == "all" ]];
then
    kubectl label nodes docker-desktop infra=true
    kubectl label nodes docker-desktop mgmt=true
    
    kubectl create ns $XGVELA_NS

    helm install $XGVELA_ID -n $XGVELA_NS $CHARTS -f $DEPLOYMENT_YAML
fi

if [[ "$1" == "upgrade" ]];
then
    helm upgrade $XGVELA_ID -n $XGVELA_NS $CHARTS -f $DEPLOYMENT_YAML
fi

if [[ "$1" == "uninstall" ]];
then
    helm -n $XGVELA_NS uninstall $XGVELA_ID
    kubectl delete ns $XGVELA_NS
fi

