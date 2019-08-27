# This script contains the commands used for attaching the lidar data tables as partitions of the parent table.

docker run -it --rm -v $(pwd):/var/data --network sioselocalnet --entrypoint /bin/bash siose-innova/postgresql-client:10

tail -n+2 h25_30.csv | tr -d - | sed 's/^[0]*//' | time parallel psql postgresql://postgres@pointcloud/lidar_alc -c \"ALTER TABLE lidar ATTACH PARTITION lidar{} FOR VALUES IN \({}\)\"