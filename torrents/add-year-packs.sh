#!/bin/bash

SCRIPT_DIR=$(cd $(dirname ${0}) && pwd)
ARCHIVE_DIR=${SCRIPT_DIR}/../mirror-storage/archive

source ${SCRIPT_DIR}/.env

QBIT_URL=http://${QBIT_HOST}:${QBIT_PORT}

# Write session into bash var
SESSION=$(curl -s -i --data-urlencode username=${QBIT_USERNAME} --data-urlencode password=${QBIT_PASSWORD} ${QBIT_URL}/api/v2/auth/login | grep -ioP 'set-cookie: \K[^;]+')

for torrent in ${ARCHIVE_DIR}/*/*.torrent; do
    year=$(basename $(dirname ${torrent}))
    echo "Adding ${torrent}"
    curl -b ${SESSION} -F torrents=@${torrent} -F savepath=/archive/${year} -F skip_checking=true ${QBIT_URL}/api/v2/torrents/add
done