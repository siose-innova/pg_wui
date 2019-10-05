FROM siose-innova/postgis:2.5.1-debian

ENV POINTCLOUD_VERSION v1.2.0
ENV LAZPERF_VERSION 1.3.0

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        cmake \
        git \
        libxml2-dev \
        postgresql-server-dev-$PG_MAJOR \
        zlib1g-dev \
    && git clone https://github.com/hobu/laz-perf.git \
    && cd laz-perf \
    && git checkout $LAZPERF_VERSION \
    && cmake . \
    && make \
    && make install \
    && cd .. \
    && git clone https://github.com/pgpointcloud/pointcloud \
    && cd pointcloud \
    && git checkout $POINTCLOUD_VERSION \
    && ./autogen.sh \
    && ./configure --with-pgconfig=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config CFLAGS="-Wall -Werror -O2 -g" \
    && make \
    && make install \
    && cd .. \
    && apt-get purge -y --auto-remove \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        cmake \
        git \
        libxml2-dev \
        postgresql-server-dev-$PG_MAJOR \
        zlib1g-dev \    
    && rm -rf laz-perf \
    && rm -rf pointcloud \
    && rm -rf /var/lib/apt/lists/*
