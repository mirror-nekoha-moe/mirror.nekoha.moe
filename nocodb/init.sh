#!/bin/bash

cp /setup.sql /tmp/setup.sql
sed -i "s/\$POSTGRES_DB/$POSTGRES_DB/g" /tmp/setup.sql
sed -i "s/\$PUBLIC_USER/$PUBLIC_USER/g" /tmp/setup.sql
sed -i "s/\$PUBLIC_PASSWORD/$PUBLIC_PASSWORD/g" /tmp/setup.sql

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /tmp/setup.sql
rm /tmp/setup.sql