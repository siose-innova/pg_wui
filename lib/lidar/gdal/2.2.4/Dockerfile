FROM alpine:edge

ENV GDAL_VERSION 2.2.4

RUN set -ex \
    \
    && apk add --no-cache \
        bash \
        bash-completion \
        tzdata \
    \
    && cp /usr/share/zoneinfo/Pacific/Quito /etc/localtime \
    && apk add --no-cache --virtual .run-deps \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        curl \
        geos \
        libpq \
        libspatialite \
        libxml2 \
        proj4 \
        python3 \
        sqlite \
    \
    && apk add --no-cache --virtual .fetch-deps \
        tar \
    \
    && wget -O gdal.tar.gz http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
    && mkdir -p /usr/src/gdal \
    && tar \
        --extract \
        --file gdal.tar.gz \
        --directory /usr/src/gdal \
        --strip-components 1 \
    && rm gdal.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        linux-headers \
    \
    && apk add --no-cache --virtual .build-deps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        sqlite-dev \
        libxml2-dev \
        curl-dev \
        proj4-dev \
        geos-dev \
        python3-dev \
        postgresql-dev \
        libspatialite-dev \
    \
    && cd /usr/src/gdal \
    && ./configure \
        --with-curl \
        --with-geos \
        --with-geotiff=internal \
        --with-hide-internal-symbols \
        --with-libtiff=internal \
        --with-libz=internal \
        --with-pg \
        --with-static-proj4 \
        --with-python \
        --with-spatialite \
        --with-sqlite3 \
        --with-threads \
        --with-xml2 \
        --without-bsb \
        --without-cfitsio \
        --without-cryptopp \
        --without-dwgdirect \
        --without-ecw \
        --without-expat \
        --without-fme \
        --without-freexl \
        --without-gif \
        --without-gnm \
        --without-grass \
        --without-grib \
        --without-hdf4 \
        --without-hdf5 \
        --without-idb \
        --without-ingres \
        --without-jasper \
        --without-jp2mrsid \
        --without-jpeg \
        --without-kakadu \
        --without-libgrass \
        --without-libkml \
        --without-libtool \
        --without-mrf \
        --without-mrsid \
        --without-mysql \
        --without-netcdf \
        --without-odbc \
        --without-ogdi \
        --without-openjpeg \
        --without-pcidsk \
        --without-pcraster \
        --without-pcre \
        --without-perl \
        --without-php \
        --without-png \
        --without-qhull \
        --without-sde \
        --without-webp \
        --without-xerces \
    \
    && make \
    && make install \
    && cd / \
    && rm -rf /usr/src/gdal \
    && apk del .fetch-deps .build-deps .build-deps-testing
