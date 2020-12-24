#! /bin/bash

IMAGEID=zk-alpine
IMAGETAG=v3.4.13

docker build -t $IMAGEID:$IMAGETAG .
docker save $IMAGEID:$IMAGETAG | gzip > $IMAGEID-$IMAGETAG.tar.gz;
echo "Generated Image: $IMAGEID-$IMAGETAG.tar.gz"
