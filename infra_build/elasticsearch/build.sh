#! /bin/bash

IMAGEID=xgvela-elasticsearch
IMAGETAG=7.8.0

docker build -t $IMAGEID:$IMAGETAG .
docker save $IMAGEID:$IMAGETAG | gzip > $IMAGEID-$IMAGETAG.tar.gz;
echo "Generated Image: $IMAGEID-$IMAGETAG.tar.gz"
