#!/bin/bash
#
# Create files with timestamp in the past
#

FILE_PREFIX="log_"
FILE_SUFFIX=".csv"

CURRENT_MONTH=$(expr "$(date +"%m")") # remove leading zero
CURRENT_DAY=$(date +"%d")
CURRENT_TIME=$(date +"%H%M")
END_MONTH=$((CURRENT_MONTH - 1))
START_MONTH=$((CURRENT_MONTH - 3))

# Comple months
for MONTH in $(seq -f %02g ${START_MONTH} ${END_MONTH}  ); do
    for DAY in $(seq -f %02g 1 31); do
        FILE_DATE="${MONTH}${DAY}${CURRENT_TIME}"
        FILE_NAME="${FILE_PREFIX}${FILE_DATE}${FILE_SUFFIX}"
        touch -t "${FILE_DATE}" "${FILE_NAME}"
    done
done

# Current month
MONTH=$(date +"%m") # with leading zero
for DAY in $(seq -f %02g 1 "${CURRENT_DAY}"); do
    FILE_DATE="${MONTH}${DAY}${CURRENT_TIME}"
    FILE_NAME="${FILE_PREFIX}${FILE_DATE}${FILE_SUFFIX}"
    touch -t "${FILE_DATE}" "${FILE_NAME}"
done
