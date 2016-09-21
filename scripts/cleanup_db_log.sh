#!/bin/bash
#
# Clean up the GreenPlum log files
#

$(dirname $0)/cleanup_dir.sh ${MASTER_DATA_DIRECTORY}/pg_log 3 false
