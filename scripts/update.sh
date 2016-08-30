#!/usr/bin/env bash
set -e

(
    # number chosen here is totally arbitrary. it is a file descriptor (FD)
    # the only problem that can happen if someone else tries to flock on the same FD
    # that case we would lock each other out. Hopefully termporarily.
    # Note that the same FD needs to be used at the end of the subprocess definition (block)
	flock -n 4263

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

) 4263>/tmp/insight-toolkit.flock
