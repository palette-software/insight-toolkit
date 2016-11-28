#!/usr/bin/env bash

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

    # Normally this folder already exists, but make sure
    mkdir -p /var/log/palette-insight-website
    export UPDATE_PROGRESS_FILE=/var/log/palette-insight-website/progress.log

    rm -f $UPDATE_PROGRESS_FILE
    export PROGRESS=0
    export PROGRESS_RANGE=20

    echo "1,$(date +"%Y-%m-%d %H:%M:%S") Starting update" > $UPDATE_PROGRESS_FILE
    sudo yum clean all
    echo "25,Yum clean completed" >> $UPDATE_PROGRESS_FILE

    # Update the base package...
    sudo yum install -y palette-insight
    PROGRESS=40
    echo "${PROGRESS},Base package (palette-insight) updated" >> $UPDATE_PROGRESS_FILE
    # ... and all of its dependencies
    export PALETTE_PACKAGES=$(rpm -qa palette* --qf "%{name}\n")
    export PACKAGE_NUM=$(echo "$PALETTE_PACKAGES" | wc -l)
    export INCREMENT=$((60 / $PACKAGE_NUM))

    for PPACKAGE in $PALETTE_PACKAGES
    do
        PROGRESS=$((PROGRESS + INCREMENT))
        echo -n "${PROGRESS},Updating ${PPACKAGE}... " >> $UPDATE_PROGRESS_FILE
        sudo yum install -y ${PPACKAGE}
        export EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo "failed" >> $UPDATE_PROGRESS_FILE
            # Mark the update as a failure, but update all the packages we can
            export UPDATE_FAILED=true
            continue
        fi
        echo "ok" >> $UPDATE_PROGRESS_FILE
    done

    if [ -z $UPDATE_FAILED ]; then
        echo "100,$(date +"%Y-%m-%d %H:%M:%S") Successfully finished update" >> $UPDATE_PROGRESS_FILE
    else
        echo "100,$(date +"%Y-%m-%d %H:%M:%S") Update failed due to failing packages!" >> $UPDATE_PROGRESS_FILE
    fi

    log "Update end"

) 863>/tmp/insight-toolkit.flock
