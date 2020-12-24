#FROM 192.168.56.104:5000/alpine_base:latest
FROM alpine:3.11.3



ARG ETCD_VER=3.3.15
#ARG ETCD_VER=3.4.10
RUN apk add --update ca-certificates openssl tar bash && \
#wget https://github.com/coreos/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz && \
#wgetcurl -L https://github.com/etcd-io/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz && \
wget https://github.com/etcd-io/etcd/releases/download/v$ETCD_VER/etcd-v$ETCD_VER-linux-amd64.tar.gz && \
tar xzvf etcd-v$ETCD_VER-linux-amd64.tar.gz && \
mv etcd-v$ETCD_VER-linux-amd64/etcd* /bin/ && \
apk del --purge tar openssl && \
rm -Rf etcd-v$ETCD_VER-linux-amd64* /var/cache/apk/*

VOLUME /data

EXPOSE 2379 2380

ADD docker-entrypoint.sh /bin/docker-entrypoint.sh

ENTRYPOINT ["/bin/docker-entrypoint.sh"]
