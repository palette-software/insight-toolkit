#!/usr/bin/env bash

# Stop execution on first error
set -e

data_model_version=$1
if [[ -n "$data_model_version" ]]; then
    echo "Requested data model version: $data_model_version"
else
    echo "No data model version specified. Trying to install the latest one."
fi

# First try to update Palette Insight Server via yum, but if it fails,
# try to perform an offline update.
/opt/insight-toolkit/yum-or-offline-update.sh palette-insight-reporting

# Figure out the relative path from the current working directory to the path of this script being run
SCRIPT_PATH="`dirname \"$0\"`"

# Find a place which is available both for centos and gpadmin user. For example /tmp will do.
sudo cp -f $SCRIPT_PATH/gpadmin-install-data-model.sh /tmp/
sudo chown gpadmin:gpadmin /tmp/gpadmin-install-data-model.sh
sudo su -c "/tmp/gpadmin-install-data-model.sh $data_model_version" gpadmin
sudo rm /tmp/gpadmin-install-data-model.sh
