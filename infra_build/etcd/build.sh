#! /bin/bash

IMAGEID=etcd-alpine
IMAGETAG=v3.3.15

docker build -t $IMAGEID:$IMAGETAG .
docker save $IMAGEID:$IMAGETAG | gzip > $IMAGEID-$IMAGETAG.tar.gz;
echo "Generated Image: $IMAGEID-$IMAGETAG.tar.gz"
