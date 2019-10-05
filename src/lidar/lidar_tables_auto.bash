# This script contains the commands used for the preparation of the database for lidar data storage using spatial partitioning.

# GDAL docker execution
docker run -it --rm -v $(pwd):/var/data siose-innova/gdal:2.2.4 /bin/bash
cd/var/data

# Creation of text files for data on zone 30
ogr2ogr -f CSV -dialect sqlite -sql "SELECT DISTINCT MTN25_CLAS FROM ficherosxhoja25 WHERE FICHERO like '%H30%' order by 1" h25_30.csv . && tail -n +2 h25_30.csv | tr -d - | sed "s/^0*//" | time parallel ogr2ogr -f CSV -dialect sqlite -sql \"SELECT substr\(FICHERO , instr\(FICHERO,\'PNOA\'\)\) FROM ficherosxhoja25 WHERE CAST\(REPLACE\(MTN25_CLAS,\'-\',\'\'\) as integer\)={}\" h30/"{}".csv .

# Creation of text files for data on zone 31
ogr2ogr -f CSV -dialect sqlite -sql "SELECT DISTINCT MTN25_CLAS FROM ficherosxhoja25 WHERE FICHERO like '%H31%' order by 1" h25_31.csv . && tail -n +2 h25_31.csv | tr -d - | sed "s/^0*//" | time parallel ogr2ogr -f CSV -dialect sqlite -sql \"SELECT substr\(FICHERO , instr\(FICHERO,\'PNOA\'\)\) FROM ficherosxhoja25 WHERE CAST\(REPLACE\(MTN25_CLAS,\'-\',\'\'\) as integer\)={}\" h31/"{}".csv .

#PostgreSQL client docker execution
docker run -it --rm -v $(pwd):/var/data --network sioselocalnet --entrypoint /bin/bash siose-innova/postgresql-client:10

# Library update and parallel installation
apk update
apk add parallel

# Tables creation for zone 30
tail -n+2 h25_30.csv | tr -d - | sed 's/^[0]*//' | time parallel psql postgresql://postgres@pointcloud/lidar_alc -c \"CREATE TABLE lidar{} \(id serial PRIMARY KEY, pa pcpatch\(1\), h25 smallint DEFAULT {} NOT NULL CHECK \(h25={}\)\)\"

#Tables creation for zone 31
tail -n+2 h25_31.csv | tr -d - | sed 's/^[0]*//' | time parallel psql postgresql://postgres@pointcloud/lidar_alc -c \"CREATE TABLE lidar{} \(id serial PRIMARY KEY, pa pcpatch\(1\), h25 smallint DEFAULT {} NOT NULL CHECK \(h25={}\)\)\"