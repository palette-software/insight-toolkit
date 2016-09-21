#!/bin/bash
#
# Deletes and might compress .csv or .csv.gz files in a directory
#

if [[ $# -ne 3 ]]; then
    echo "Usage $0 <directory> <last_n_days> <should_compress>"
    exit 1
fi

LOG_DIR=$1
LOG_DAYS=$2
LOG_COMPRESS=$3

echo "Clean up log files in ${LOG_DIR} older than ${LOG_DAYS} days"
find "${LOG_DIR}" -mtime +"${LOG_DAYS}" \( -name \*.csv -or -name \*.csv.gz \) -delete -print

if [[ "${LOG_COMPRESS}" == true ]]; then
    # It will compress all files older than 24 hours. Could happen that the last two files will remain uncompressed
    echo "Compress log files in ${LOG_DIR}"
    find "${LOG_DIR}" -mtime +0 -name \*.csv -exec gzip -9 {} \; -print
fi
