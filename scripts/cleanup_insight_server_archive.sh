#!/bin/bash
#
# Clean up the .csv.gz files in the archive directory
#

INSIGHT_SERVER_DATA_DIR="/data/insight-server/uploads"

CLUSTER_DIRS=$(find ${INSIGHT_SERVER_DATA_DIR} -type d -depth 1)

for CLUSTER_DIR in ${CLUSTER_DIRS}; do
    ARCHIVE_DIRS=$(find "${CLUSTER_DIR}/archive" -type d -depth 1)
    for ARCHIVE_DIR in ${ARCHIVE_DIRS}; do
        "$(dirname "$0")"/cleanup_dir.sh "${ARCHIVE_DIR}" 61 false
    done
done
