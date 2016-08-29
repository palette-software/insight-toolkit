#!/usr/bin/env bash

if [[ -z $UPDATE_PROGRESS_FILE ]]; then
	echo "Insight UPDATE_PROGRESS_FILE is not set! Exiting..."
	exit 1
fi

insight_product=$1
if [[ -n "$insight_product" ]]; then
    echo "Offline updating Insight product: $insight_product"
else
    echo "Missing parameter!"
    echo "Usage: update-insight-locally.sh <product>"
    exit 1
fi

# By convention the update file needs to be located in the /tmp folder
offline_update_file=/tmp/$insight_product.rpm
echo "Looking for $offline_update_file ..." >> $UPDATE_PROGRESS_FILE

rpm -Uvh $offline_update_file
return_code=$?

# FIXME: This echo is only for debugging purposes. It shall be removed later.
echo "Return code of rpm command: $return_code"

if [[ return_code -eq 2 ]]; then
	echo "Skipped offline update as newer version of $insight_product is already installed."
	exit 0
fi

if [[ return_code -ne 0 ]]; then
	echo "Failed to update $insight_product offline!" >> $UPDATE_PROGRESS_FILE
	exit 1
fi

echo "Successfully updated $insight_product offline." >> $UPDATE_PROGRESS_FILE
exit 0
