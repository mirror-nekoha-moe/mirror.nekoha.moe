#!/bin/bash

# Load .env file (PSQL Credentials)
export $(grep -v '^#' ../.env.psql | xargs)

# Base folder path
BASE_PATH="/home/admin/git/mirror.nekoha.moe/beatmap-fetcher/storage"

# Counters
checked_count=0

# Get all IDs from the table
ids=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c "SELECT id FROM beatmapset_metadata;")

# Loop over each ID
for id in $ids; do
    folder="$BASE_PATH/$id"
    if [ -d "$folder" ]; then
        checked_count=$((checked_count+1))
        # Check for .osz files
        if ! compgen -G "$folder/*.osz" > /dev/null; then
            echo "Folder $id has no .osz files"
        fi
    else
        echo "Folder $id does not exist (download disabled?)"
    fi
done

# Print totals
total_size=$(du -sh "$BASE_PATH" | awk '{print $1}')
echo "Checked folders: $checked_count"
echo "Total size of $BASE_PATH: $total_size"
