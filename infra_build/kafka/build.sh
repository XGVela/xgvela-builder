#! /bin/bash

IMAGEID=kafka-alpine
IMAGETAG=v2.1.0-3

docker build -t $IMAGEID:$IMAGETAG .
docker save $IMAGEID:$IMAGETAG | gzip > $IMAGEID-$IMAGETAG.tar.gz;
echo "Generated Image: $IMAGEID-$IMAGETAG.tar.gz"
