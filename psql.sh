#!/bin/bash
export $(grep -v '^#' .env | xargs)

psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER";