#!/bin/bash

set -eo pipefail

# Load DB credentials
export $(grep -v '^#' "$(dirname "$0")/../.env" | xargs)

BASE_PATH="/home/admin/git/mirror.nekoha.moe/beatmap-fetcher/storage"

# 1st param: resume after a specific id
# remove GROUP BY file_size and set id
RESUME_AFTER="${1:-0}"

checked=0
corrupt=0
missing=0
ok=0

COUNTER_FILE=$(mktemp)
echo "0 0 0 0" > "$COUNTER_FILE"

cleanup() {
    rm -f "$COUNTER_FILE"
    echo ""
    echo "Done."
    echo "Checked: $checked"
    echo "Ok: $ok"
    echo "Corrupt: $corrupt"
    echo "Missing: $missing"
}

print_progress() {
    read -r c o co mi < "$COUNTER_FILE" 2>/dev/null || true
    echo -ne "Total: ${c:-0} OK: ${o:-0} Corrupt: ${co:-0} Missing: ${mi:-0}\r"
}

sql="SELECT id FROM $TABLE_BEATMAPSET WHERE status IN ('graveyard') AND downloaded = true AND id > ${RESUME_AFTER} ORDER BY file_size;"

echo "Fetch Query: $sql"
ids=$(psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -t -A -c "$sql")

total=$(echo "$ids" | grep -c '[0-9]' || true)
echo "Found $total beatmapsets to check (resuming after ID $RESUME_AFTER)."

for id in $ids; do
    id=$(echo "$id" | tr -d '[:space:]')
    [ -z "$id" ] && continue

    folder="$BASE_PATH/$id"
    checked=$((checked + 1))
    echo "$checked $ok $corrupt $missing" > "$COUNTER_FILE"
    
    # Find the .osz file (pick largest if multiple)
    osz_file=""
    best_size=-1
    while IFS= read -r -d '' f; do
        sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
        if [ "$sz" -gt "$best_size" ]; then
            best_size=$sz
            osz_file=$f
        fi
    done < <(find "$folder" -maxdepth 1 -name "*.osz" -print0 2>/dev/null)

    if [ -z "$osz_file" ]; then
        missing=$((missing + 1))
        echo "$checked $ok $corrupt $missing" > "$COUNTER_FILE"
        # Mark not downloaded so fetcher picks it up
        psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -q \
            -c "UPDATE beatmapset_metadata SET downloaded = false WHERE id = $id;" 2>/dev/null || true
        continue
    fi

    # Validate zip using Python (checks for EOCD signature reliably)
    # Invalidate empty archives
    if python3 -c "import zipfile,sys; z=zipfile.ZipFile(sys.argv[1]); sys.exit(0 if z.infolist() else 1)" "$osz_file" 2>/dev/null; then
        valid=1
    else
        valid=0
    fi

    if [ "$valid" -eq 0 ]; then
        corrupt=$((corrupt + 1))
        echo "$checked $ok $corrupt $missing" > "$COUNTER_FILE"
        echo -e "\n[CORRUPT] $id - $(basename "$osz_file") ($best_size bytes) → deleting"
        rm -f "$osz_file"
        psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -q \
            -c "UPDATE beatmapset_metadata SET downloaded = false WHERE id = $id;" 2>/dev/null || true
    else
        ok=$((ok + 1))
        echo -e "\n[OK] $id - $(basename "$osz_file") ($best_size bytes)"
        echo "$checked $ok $corrupt $missing" > "$COUNTER_FILE"
    fi
    print_progress
done

cleanup()