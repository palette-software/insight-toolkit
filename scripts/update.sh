#!/usr/bin/env bash

# Stop execution on the first error. Even if the error
# is within the subshell (the block within parentheses).
set -e

(
    # The number chosen here is totally arbitrary. It is a file descriptor (FD).
    # The only problem that can happen if someone else tries to flock on the same FD.
    # In that case we would lock each other out. Hopefully termporarily.
    # Note that the same FD needs to be used at the end of the subprocess definition (block).
    # And by default the ulimit -n (the maximum number of open file descriptors) value is
    # 1024, so it's safer to pick a number under 1024.
	flock -n 863

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

) 863>/tmp/insight-toolkit.flock
