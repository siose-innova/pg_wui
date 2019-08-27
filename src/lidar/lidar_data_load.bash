# PDAL docker execution
docker run -it --rm --network sioselocalnet -v $(pwd):/var/data siose-innova/pdal:1.8 /bin/bash

time for f in h30/*.csv; do export n=${f:4:4}; echo $n; tail -n +2 $f | time parallel pdal pipeline pipeline.json --stage.input.filename=\"{}\" --stage.output.connection=\"host=pointcloud dbname=lidar_alc user=postgres\" --stage.output.table=\"lidar$n\"; done >log 2>&1