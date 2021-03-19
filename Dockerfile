FROM    debian:buster

ENV     WHIRLPOOL_HOME                /home/whirlpool
ENV     WHIRLPOOL_DIR                 /usr/local/whirlpool-cli

# Install prerequisites
# Create group & user whirlpool
# Create .whirlpool-cli subdirectory of WHIRLPOOL_HOME
# Create /usr/local/src/whirlpool-cli directory
RUN     set -ex && \
        apt-get update && \
        apt-get install -y libevent-dev zlib1g-dev libssl-dev gcc make automake ca-certificates autoconf musl-dev coreutils gpg wget default-jdk && \
        addgroup --system -gid 1000 whirlpool && \
        adduser --system --ingroup whirlpool -uid 1000 whirlpool && \
        mkdir -p "$WHIRLPOOL_HOME/.whirlpool-cli" && \
        chown -Rv whirlpool:whirlpool "$WHIRLPOOL_HOME" && \
        chmod -R 750 "$WHIRLPOOL_HOME" && \
        mkdir -p "$WHIRLPOOL_DIR"

# Install Tor
ENV     WHIRLPOOL_TOR_URL             https://dist.torproject.org
ENV     WHIRLPOOL_TOR_MIRROR_URL      https://tor.eff.org/dist
ENV     WHIRLPOOL_TOR_VERSION         0.4.4.8
ENV     WHIRLPOOL_TOR_GPG_KS_URI      hkp://keyserver.ubuntu.com:80
ENV     WHIRLPOOL_TOR_GPG_KEY1        0xEB5A896A28988BF5
ENV     WHIRLPOOL_TOR_GPG_KEY2        0xC218525819F78451
ENV     WHIRLPOOL_TOR_GPG_KEY3        0x21194EBB165733EA
ENV     WHIRLPOOL_TOR_GPG_KEY4        0x6AFEE6D49E92B601

RUN     set -ex && \
        mkdir -p /usr/local/src/ && \
        cd /usr/local/src && \
        res=0; \
        wget -qO "tor-$WHIRLPOOL_TOR_VERSION.tar.gz" "$WHIRLPOOL_TOR_URL/tor-$WHIRLPOOL_TOR_VERSION.tar.gz" || res=$?; \
        if [ $res -gt 0 ]; then \
          wget -qO "tor-$WHIRLPOOL_TOR_VERSION.tar.gz" "$WHIRLPOOL_TOR_MIRROR_URL/tor-$WHIRLPOOL_TOR_VERSION.tar.gz"; \
        fi && \
        res=0; \
        wget -qO "tor-$WHIRLPOOL_TOR_VERSION.tar.gz.asc" "$WHIRLPOOL_TOR_URL/tor-$WHIRLPOOL_TOR_VERSION.tar.gz.asc" || res=$?; \
        if [ $res -gt 0 ]; then \
          wget -qO "tor-$WHIRLPOOL_TOR_VERSION.tar.gz.asc" "$WHIRLPOOL_TOR_MIRROR_URL/tor-$WHIRLPOOL_TOR_VERSION.tar.gz.asc" ; \
        fi && \
        gpg --keyserver "$WHIRLPOOL_TOR_GPG_KS_URI" --recv-keys "$WHIRLPOOL_TOR_GPG_KEY1" && \
        gpg --keyserver "$WHIRLPOOL_TOR_GPG_KS_URI" --recv-keys "$WHIRLPOOL_TOR_GPG_KEY2" && \
        gpg --keyserver "$WHIRLPOOL_TOR_GPG_KS_URI" --recv-keys "$WHIRLPOOL_TOR_GPG_KEY3" && \
        gpg --keyserver "$WHIRLPOOL_TOR_GPG_KS_URI" --recv-keys "$WHIRLPOOL_TOR_GPG_KEY4" && \
        gpg --verify "tor-$WHIRLPOOL_TOR_VERSION.tar.gz.asc" && \
        tar -xzvf "tor-$WHIRLPOOL_TOR_VERSION.tar.gz" -C /usr/local/src && \
        cd "/usr/local/src/tor-$WHIRLPOOL_TOR_VERSION" && \
        ./configure \
            --disable-asciidoc \
            --sysconfdir=/etc \
            --disable-unittests && \
        make && make install && \
        cd .. && \
        rm -rf "tor-$WHIRLPOOL_TOR_VERSION" && \
        rm "tor-$WHIRLPOOL_TOR_VERSION.tar.gz" && \
        rm "tor-$WHIRLPOOL_TOR_VERSION.tar.gz.asc"

# Install whirlpool-cli
ENV     WHIRLPOOL_URL                 https://code.samourai.io/whirlpool/whirlpool-client-cli/uploads
ENV     WHIRLPOOL_VERSION             0.10.10
ENV     WHIRLPOOL_VERSION_HASH        e4a90d89e67b90b7c715a12264ebc8fd
ENV     WHIRLPOOL_JAR                 "whirlpool-client-cli-$WHIRLPOOL_VERSION-run.jar"
ENV     WHIRLPOOL_SHA256              07f76fba4cc07ae3b7852819a4b336a326b25d1c4454187538c75611160c0852

RUN     set -ex && \
        cd "$WHIRLPOOL_DIR" && \
        echo "$WHIRLPOOL_SHA256 *$WHIRLPOOL_JAR" > WHIRLPOOL_CHECKSUMS && \
        wget -qO "$WHIRLPOOL_JAR" "$WHIRLPOOL_URL/$WHIRLPOOL_VERSION_HASH/$WHIRLPOOL_JAR" && \
        sha256sum -c WHIRLPOOL_CHECKSUMS 2>&1 | grep OK && \
        mv "$WHIRLPOOL_JAR" whirlpool-client-cli-run.jar && \
        chown -Rv whirlpool:whirlpool "$WHIRLPOOL_DIR" && \
        chmod -R 750 "$WHIRLPOOL_DIR"

# Copy restart script
COPY    ./entrypoint.sh /entrypoint.sh

RUN     chown whirlpool:whirlpool /entrypoint.sh && \
        chmod u+x /entrypoint.sh && \
        chmod g+x /entrypoint.sh

# Expose HTTP API port
EXPOSE  8898

# Switch to user whirlpool
USER    whirlpool

ENTRYPOINT [ "entrypoint.sh" ]
