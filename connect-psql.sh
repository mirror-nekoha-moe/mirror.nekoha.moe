#!/bin/bash
export $(grep -v '^#' .env.psql | xargs)

psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME";
