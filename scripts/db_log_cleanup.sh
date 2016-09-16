#!/bin/bash

LOG_DIR=${MASTER_DATA_DIRECTORY}/pg_log
LOG_DAYS=14
echo "Clean up log files in ${LOG_DIR} older than ${LOG_DAYS} days"
find ${LOG_DIR} -mtime +${LOG_DAYS} \( -name \*.csv -or -name \*.csv.gz \) -delete -print

# It will compress all files older than 24 hours. So the last two files will remain uncompressed
echo "Compress log files in ${LOG_DIR}"
find ${LOG_DIR} -mtime +0 -name \*.csv -exec gzip -9 {} \; -print
