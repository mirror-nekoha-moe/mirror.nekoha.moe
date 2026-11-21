#!/bin/bash

if [ -z $1 ]; then
    echo "Usage: $0 <year>"
    exit 1
fi

YEAR=${1}
SCRIPT_DIR=$(cd $(dirname ${0}) && pwd)
YEAR_DIR=${SCRIPT_DIR}/../mirror-storage/archive/${YEAR}
TEMP_DIR=${SCRIPT_DIR}/temp
YEAR_TEMP=${TEMP_DIR}/${YEAR}

# Remove temp files
rm -rf ${TEMP_DIR}/*

mkdir -p ${YEAR_TEMP}
cd ${YEAR_TEMP}

echo "Downloading ${YEAR} month packs"
cp ${YEAR_DIR}/*/*.zip .

# We are inside $YEAR_TEMP
for month_zip in $(ls); do
    month_name=$(echo ${month_zip} | sed 's/\.zip$//')
    mode=${month_name:8}
    name=${YEAR}-${mode}

    mkdir -p ${name}
    unzip -j ${month_zip} -d ${name}
    rm ${month_zip}
done

for name in $(ls); do
    echo "Building ${name}.zip"
    zip -0 -r ${name}.zip ${name}
    mktorrent -o ${name}.torrent ${name}.zip

    echo "Uploading ${name}"
    cp ${name}.zip ${name}.torrent ${YEAR_DIR}
done

cd ${SCRIPT_DIR}
rm -rf ${YEAR_TEMP}