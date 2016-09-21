#!/bin/bash
#
# Clean up the .csv.gz files in the archive directory
#

"$(dirname "$0")"/cleanup_dir.sh /data/insight-server/uploads/*/archive/ 61 false
