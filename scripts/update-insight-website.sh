#!/usr/bin/env bash

# Stop on the first error
set -e

# First try to update Palette Insight Server via yum, but if it fails,
# try to perform an offline update.
/opt/insight-toolkit/yum-or-offline-update.sh palette-insight-website

# Don't restart it here as it would stop running the whole update script.
# sudo supervisorctl restart insight-services-webui

exit 0
