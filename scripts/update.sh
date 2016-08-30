#!/usr/bin/env bash
set -e

(
	flock -n 200

	echo "$(date +"%Y-%m-%d %H:%M:%S") Update start"

	export UPDATE_PROGRESS_FILE=/var/log/insight-services/progress.log

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Server"
	/opt/insight-toolkit/update-insight-server.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Server"

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Data Model"
	/opt/insight-toolkit/update-data-model.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Data Model"

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Load"
	/opt/insight-toolkit/update-loadtables.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Load"

) 200>/tmp/insight-toolkit.flock
