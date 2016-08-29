#!/usr/bin/env bash

# Stop on the first error
set -e

# First try to update Palette Insight Server via yum, but if it fails,
# try to perform an offline update.
/opt/update-insight/yum-or-offline-update.sh palette-insight-server

sudo supervisorctl restart palette-insight-server
sudo service nginx restart

exit 0
