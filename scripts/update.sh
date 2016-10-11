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

    export TWOZEROFIRSTTIME=0
    if [ ! -d "/data/insight-server/uploads/palette" ]; then
        # Steps needed only for 1.x -> 2.x upgrade
        export LOADTABLES_LOCKFILE=/tmp/PI_ImportTables_prod.flock
        flock -w 600 $LOADTABLES_LOCKFILE /opt/insight-toolkit/2-0-upgrade.sh
        export TWOZEROFIRSTTIME=1
    fi

    # Steps needed for anything else

	echo "$(date +"%Y-%m-%d %H:%M:%S") Update start"

	export UPDATE_PROGRESS_FILE=/var/log/insight-services/progress.log

    rm -rf $UPDATE_PROGRESS_FILE
    export PROGRESS=0
    export PROGRESS_RANGE=20

    echo "1,Starting update" > $UPDATE_PROGRESS_FILE
    sudo yum clean all
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Toolkit"
    export PROGRESS=10
	/opt/insight-toolkit/update-insight-toolkit.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Toolkit"

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Website"
    export PROGRESS=30
	/opt/insight-toolkit/update-insight-website.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Website"

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Server"
    export PROGRESS=50
	/opt/insight-toolkit/update-insight-server.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Server"

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Data Model"
    export PROGRESS=70
    export PROGRESS_RANGE=10
	/opt/insight-toolkit/update-data-model.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Data Model"
    
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Agent"
    export PROGRESS=80
	/opt/insight-toolkit/update-insight-agent.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Agent"
    
    echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight Reporting Framework"
    export PROGRESS=90
    export PROGRESS_RANGE=5
	/opt/insight-toolkit/update-insight-reporting-framework.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight Reporting Framework"

	echo "$(date +"%Y-%m-%d %H:%M:%S") Updating Palette Insight GP-Import"
    export PROGRESS=95
	/opt/insight-toolkit/update-insight-gp-import.sh
	echo "$(date +"%Y-%m-%d %H:%M:%S") Updated Palette Insight GP-Import"
    echo "100,$(date +"%Y-%m-%d %H:%M:%S") Successfully finished update" >> $UPDATE_PROGRESS_FILE

    # Now take a big breath and restart ourselves.
    # The problem is if this fails we would never start up again.
    sleep 10
    rm -rf $UPDATE_PROGRESS_FILE
    sudo supervisorctl restart insight-services-webui

    if [ "$TWOZEROFIRSTTIME" == "1" ]; then
        flock -w 600 $LOADTABLES_LOCKFILE /opt/insight-toolkit/2-0-upgrade-post.sh
    fi


) 863>/tmp/insight-toolkit.flock
