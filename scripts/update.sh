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


    log () {
        echo "$(date +"%Y-%m-%d %H:%M:%S") $*"
    }

    # Steps needed for anything else

    log "Update start"

    export UPDATE_PROGRESS_FILE=/var/log/insight-services/progress.log

    rm -rf $UPDATE_PROGRESS_FILE
    export PROGRESS=0
    export PROGRESS_RANGE=20

    echo "1,Starting update" > $UPDATE_PROGRESS_FILE
    sudo yum clean all
    echo "25,Yum clean completed" >> $UPDATE_PROGRESS_FILE

    # Update the base package...
    sudo yum install -y palette-insight
    echo "40,Dependencies updated" >> $UPDATE_PROGRESS_FILE
    # ... and all of its dependencies
    LC_ALL=C repoquery --requires palette-insight | xargs sudo yum install -y && echo "100,$(date +"%Y-%m-%d %H:%M:%S") Successfully finished update" >> $UPDATE_PROGRESS_FILE

    log "Update end"

) 863>/tmp/insight-toolkit.flock
