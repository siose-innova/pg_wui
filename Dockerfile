ARG BASE
FROM $BASE

ARG SCHEMA
ENV SIOSE_SCHEMA=$SCHEMA

COPY ./src /usr/src/pg_wui

RUN set -ex \
    \
    && apk add --no-cache --virtual .build-deps \
        make \
    && cd /usr/src/pg_wui \
    && make \
    && make install \
    && cd / \
    && rm -rf /usr/src/pg_wui \
    && apk del .build-deps
