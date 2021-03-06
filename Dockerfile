FROM alpine:3.6

MAINTAINER Dan Porter <dpreid@gmail.com>

RUN adduser -S bitcoin

ENV BERKELEYDB_VERSION=db-4.8.30.NC \
  BERKELEYDB_SHASUM="12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef"
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

ENV BITCOIN_VERSION=0.14.2-uasfsegwit1.0 \
  BITCOIN_SHASUM="bd96dcd7932bfeb272ac421bd958db1ffccba1a763f44310866edb52d0a843ce"
ENV BITCOIN_PREFIX=/opt/bitcoin-${BITCOIN_VERSION} \
  BITCOIN_DATA=/home/bitcoin/.bitcoin
ENV PATH=${BITCOIN_PREFIX}/bin:$PATH

RUN apk --no-cache --virtual build-dependencies add autoconf \
    automake \
    boost-dev \
    build-base \
    chrpath \
    file \
    libevent-dev \
    libressl \
    libtool \
    linux-headers \
    libressl-dev \
    protobuf-dev \
    zeromq-dev \
  && mkdir -p /tmp/build \
  && wget -O /tmp/build/${BERKELEYDB_VERSION}.tar.gz http://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz \
  && echo "${BERKELEYDB_SHASUM}  /tmp/build/${BERKELEYDB_VERSION}.tar.gz" | sha256sum -c \
  && wget -O /tmp/build/v${BITCOIN_VERSION}.tar.gz https://github.com/UASF/bitcoin/archive/v${BITCOIN_VERSION}.tar.gz \
  && echo "${BITCOIN_SHASUM}  /tmp/build/v${BITCOIN_VERSION}.tar.gz" | sha256sum -c \
  && tar -xzf /tmp/build/${BERKELEYDB_VERSION}.tar.gz -C /tmp/build/ \
  && sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i /tmp/build/${BERKELEYDB_VERSION}/dbinc/atomic.h \
  && mkdir -p ${BERKELEYDB_PREFIX} \
  && cd /tmp/build/${BERKELEYDB_VERSION}/build_unix \
  && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX} \
  && make install \
  && tar -xzf /tmp/build/v${BITCOIN_VERSION}.tar.gz -C /tmp/build/ \
  && cd /tmp/build/bitcoin-${BITCOIN_VERSION} \
  && ./autogen.sh \
  && ./configure LDFLAGS=-L${BERKELEYDB_PREFIX}/lib/ CPPFLAGS=-I${BERKELEYDB_PREFIX}/include/ \
    --prefix=${BITCOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon \
  && make install \
  && cd / \
  && strip ${BITCOIN_PREFIX}/bin/bitcoin-cli ${BITCOIN_PREFIX}/bin/bitcoind ${BITCOIN_PREFIX}/bin/bitcoin-tx ${BITCOIN_PREFIX}/lib/libbitcoinconsensus.a ${BITCOIN_PREFIX}/lib/libbitcoinconsensus.so.0.0.0 \
  && rm -rf /tmp/build ${BERKELEYDB_PREFIX}/docs \
  && apk --no-cache --purge del build-dependencies \
  && apk --no-cache add boost \
    boost-program_options \
    libevent \
    libzmq \
    libressl \
    su-exec

VOLUME ["/home/bitcoin/.bitcoin"]

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8332 8333 18332 18333 18444

CMD ["bitcoind"]
