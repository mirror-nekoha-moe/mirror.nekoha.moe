#!/bin/bash
set -euo pipefail

export $(grep -v '^#' "$(dirname "$0")/../../.env" | xargs)

export PGHOST="$DB_HOST"
export PGDATABASE="$DB_NAME"
export PGUSER="$DB_USER"

REMOTE_PATH="/home/beatmap-storage"

{
    echo "BEGIN;"

    tail -n +2 "temp.csv" | while IFS=, read -r beatmapset_id last_error; do

        #[[ "$last_error" == "no parseable .osu in archive" ]] || continue

        echo "Deleting ${REMOTE_PATH}/${beatmapset_id}" >&2

        ssh -o BatchMode=yes storagebox \
            "rm -rf '${REMOTE_PATH}/${beatmapset_id}'" </dev/null >&2

        printf 'UPDATE %s SET downloaded = false WHERE id = %s;\n' \
            "$TABLE_BEATMAPSET" "$beatmapset_id"

    done

    echo "COMMIT;"
} | psql -v ON_ERROR_STOP=1