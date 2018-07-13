#!/bin/sh

set -e

# Create the 'template_postgis' template db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE DATABASE template_postgis;
  UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
EOSQL

# Load PostGIS into both template_database and $POSTGRES_DB
for DB in template_postgis "$POSTGRES_DB"; do
  echo "Loading PostGIS and plpython3u extensions into $DB"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DB"<<-EOSQL
    CREATE EXTENSION IF NOT EXISTS plpython3u;
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
EOSQL
done
