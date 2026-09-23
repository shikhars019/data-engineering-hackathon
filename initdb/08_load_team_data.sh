#!/bin/bash
# ---------------------------------------------------------------------------
# 08 - Load this team's Challenge 1 dataset.
#
# Runs automatically the first time the database starts. The TEAM number
# comes from docker-compose.yml, which ./start.sh sets for you.
# ---------------------------------------------------------------------------
set -e

TEAM="${TEAM:-1}"
DATA_FILE="/teamdata/team${TEAM}.sql"

echo "-------------------------------------------------------------"
echo " Loading dataset for TEAM ${TEAM}"
echo "-------------------------------------------------------------"

if [ ! -f "$DATA_FILE" ]; then
    echo "ERROR: no data file found at ${DATA_FILE}" >&2
    echo "Expected one of: /teamdata/team1.sql .. /teamdata/team5.sql" >&2
    ls -la /teamdata/ >&2 || true
    exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -q -f "$DATA_FILE"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -q <<SQL
INSERT INTO meta.dataset_info (team) VALUES (${TEAM});
ANALYZE;
SQL

echo " Team ${TEAM} dataset loaded."
echo "-------------------------------------------------------------"
