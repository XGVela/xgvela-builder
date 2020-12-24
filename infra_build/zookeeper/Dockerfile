FROM openjdk:8-jre-alpine
#FROM 192.168.56.104:5000/8-jre-alpine:latest

# Install required packages
RUN apk add --no-cache \
    bash \
    su-exec

ENV ZK_USER=zookeeper \
    ZK_DATA_DIR=/var/lib/zookeeper/data \
    ZK_DATA_LOG_DIR=/var/lib/zookeeper/log \
    ZK_LOG_DIR=/var/log/zookeeper \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    ZK_CLIENT_PORT=2181 \
    ZK_SERVER_PORT=2888 \
    ZK_ELECTION_PORT=3888 

ARG ZK_DIST=zookeeper-3.4.13
# Create a user for the zookeeper process and configure file system ownership
# for necessary directories and symlink the distribution as a user executable
RUN set -ex \
    && adduser -D "$ZK_USER" \
    && [ `id -u $ZK_USER` -eq 1000 ] \
    && [ `id -g $ZK_USER` -eq 1000 ] \
    && mkdir -p /opt $ZK_DATA_DIR $ZK_DATA_LOG_DIR $ZK_LOG_DIR /usr/share/zookeeper /tmp/zookeeper /usr/etc/ \
    && chown -R "$ZK_USER:$ZK_USER" $ZK_DATA_DIR $ZK_LOG_DIR $ZK_DATA_LOG_DIR /tmp/zookeeper 

ARG GPG_KEY=C61B346552DC5E0CB53AA84F59147497767E7473
# Download Apache Zookeeper, verify its PGP signature, untar and clean up
RUN set -ex; \
    apk add --no-cache --virtual .build-deps \
            ca-certificates \
            gnupg \
            libressl; \
    wget -q "https://archive.apache.org/dist/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz"; \
    wget -q "https://archive.apache.org/dist/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz.asc"; \  
    export GNUPGHOME="$(mktemp -d)"; \
    echo "Image Verfication....."; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-key "$GPG_KEY" || \
    gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEY"; \
    gpg --batch --verify "$ZK_DIST.tar.gz.asc" "$ZK_DIST.tar.gz"; \
    mkdir -p /opt; \
    tar -xzf "$ZK_DIST.tar.gz" -C /opt; \
    rm -rf "$GNUPGHOME" "$ZK_DIST.tar.gz" "$ZK_DIST.tar.gz.asc"; \
    chown -R "$ZK_USER:$ZK_USER" /opt/$ZK_DIST; \
    ln -s /opt/$ZK_DIST /opt/zookeeper; \
    rm -rf /opt/zookeeper/CHANGES.txt \
           /opt/zookeeper/README.txt \
           /opt/zookeeper/NOTICE.txt \
           /opt/zookeeper/CHANGES.txt \
           /opt/zookeeper/README_packaging.txt \
           /opt/zookeeper/build.xml \
           /opt/zookeeper/config \
           /opt/zookeeper/contrib \
           /opt/zookeeper/dist-maven \
           /opt/zookeeper/docs \
           /opt/zookeeper/ivy.xml \
           /opt/zookeeper/ivysettings.xml \
           /opt/zookeeper/recipes \
           /opt/zookeeper/src \
           /opt/zookeeper/$ZK_DIST.jar.asc \
           /opt/zookeeper/$ZK_DIST.jar.md5 \
           /opt/zookeeper/$ZK_DIST.jar.sha1; \
    ln -s /opt/zookeeper/conf/ /usr/etc/zookeeper; \
    ln -s /opt/zookeeper/bin/* /usr/bin; \
    ln -s /opt/zookeeper/$ZK_DIST.jar /usr/share/zookeeper/; \
    ln -s /opt/zookeeper/lib/* /usr/share/zookeeper; \
    apk del .build-deps

# Copy configuration generator script to bin
COPY zkGenConfig.sh zkOk.sh zkMetrics.sh /opt/zookeeper/bin/

EXPOSE $ZK_CLIENT_PORT $ZK_SERVER_PORT $ZK_ELECTION_PORT
WORKDIR /opt/zookeeper/
VOLUME ["$ZK_DATA_DIR", "$ZK_DATA_LOG_DIR", "$ZK_LOG_DIR"]
ENV PATH=$PATH:/opt/zookeeper/bin/:/usr/bin/ 
ENTRYPOINT ["/opt/zookeeper/bin/zkGenConfig.sh"]
CMD ["zkServer.sh", "start-foreground"]

