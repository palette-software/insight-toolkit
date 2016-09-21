#!/bin/bash
#
# Clean up the GreenPlum log files
#

$(dirname $0)/file_cleanup.sh ${MASTER_DATA_DIRECTORY}/pg_log 3 false
