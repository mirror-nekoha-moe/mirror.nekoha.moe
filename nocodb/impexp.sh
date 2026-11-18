#!/bin/bash

DUMP=/tmp/mirror.dump

TABLES=""
for table in $SYNC_TABLES; do
    TABLES="$TABLES -t $table"
done

export_db() {
    PGPASSWORD=$PG_PASSWORD pg_dump -h $PG_HOSTNAME -p $PG_PORT -U $PG_USERNAME -d $PG_DATABASE -Fc $TABLES -f $DUMP
}

import_db() {
    PGPASSWORD=$POSTGRES_PASSWORD pg_restore -h nocodb-postgres -U $POSTGRES_USER -d $POSTGRES_DB \
        --clean --if-exists --no-owner --no-privileges --single-transaction $DUMP
}

while true; do
    if export_db && import_db; then
        rm -f $DUMP
        sleep $SYNC_SECONDS
    else
        rm -f $DUMP
        sleep 60
    fi
done