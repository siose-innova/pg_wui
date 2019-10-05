FROM alpine:3.8 
RUN set -ex \
  \
  && apk add --no-cache \
  bash \
  bash-completion \
  postgresql-client
ENTRYPOINT [ "psql" ]
