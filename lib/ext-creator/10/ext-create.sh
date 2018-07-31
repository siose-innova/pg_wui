#!/bin/bash

set -e

until psql --host "$HOST" --username "$USER" --dbname "$DB" -c '\l'; do
  >&2 echo "PostgreSQL is not ready. Will retry later."
  sleep 5
done
>&2 echo "Connection successful."

# Load $EXTNAME into $DB
echo "Loading $EXTNAME into $DB"
  psql -v ON_ERROR_STOP=1 --host "$HOST" --username "$USER" --dbname "$DB"<<-EOSQL
    \timing
    CREATE EXTENSION IF NOT EXISTS "$EXTNAME";
    VACUUM ANALYZE;
EOSQL
