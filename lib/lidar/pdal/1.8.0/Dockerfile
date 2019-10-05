FROM pdal/pdal:1.8
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
       time \
       parallel; \
    rm -rf /var/lib/apt/lists/*
