#!/bin/bash

# Load .env file (PSQL Credentials)
export $(grep -v '^#' ../.env.psql | xargs)

BASE_PATH="/home/admin/git/mirror.nekoha.moe/beatmap-fetcher/storage"

checked_count=0
no_files=0
no_folder=0

# File to share counter with background process
COUNTER_FILE=$(mktemp)
echo 0 > "$COUNTER_FILE"

# Get all IDs from the table
ids=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -c 
    "SELECT id FROM beatmapset_metadata ORDER BY id;"
)

# Function to print live counter every second
watch_counter() {
    while true; do
        count=$(cat "$COUNTER_FILE")
        echo -ne "Checked folders so far: $count\r"
        sleep 1
    done
}

# Start watcher in the background
watch_counter &
WATCH_PID=$!

# Clean up on exit
cleanup() {
    kill $WATCH_PID 2>/dev/null
    rm -f "$COUNTER_FILE"
    echo -e "\nExiting..."
    echo "Checked folders: $checked_count"
    echo "No files: $no_files"
    echo "No folder: $no_folder"
    total_size=$(du -sh "$BASE_PATH" | awk '{print $1}')
    echo "Total size of $BASE_PATH: $total_size"
}
trap cleanup EXIT SIGINT

# Loop over each ID
for id in $ids; do
    folder="$BASE_PATH/$id"
    if [ -d "$folder" ]; then
        checked_count=$((checked_count+1))
        echo $checked_count > "$COUNTER_FILE"
        if ! compgen -G "$folder/*.osz" > /dev/null; then
            no_files=$((no_files+1))
        fi
    else
        no_folder=$((no_folder+1))
    fi
done

# Trigger final cleanup
exit

