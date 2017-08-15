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

    progress() {
        echo "${PROGRESS},$*" >> $UPDATE_PROGRESS_FILE
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
    PROGRESS=30
    progress "Collecting palette packages"

    # Collect the palette packages, but make sure 'palette-insight' is the last one in the list
    export PALETTE_PACKAGES=$(rpm -qa palette* --qf "%{name}\n" | grep -v "^palette-insight$")
    # Add 'palette-insight' to the end of the list
    export PALETTE_PACKAGES+=$'\npalette-insight'
    export PACKAGE_NUM=$(echo "$PALETTE_PACKAGES" | wc -l)
    export INCREMENT=$(((100 - $PROGRESS) / $PACKAGE_NUM))

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

    PROGRESS=100
    if [ -z $UPDATE_FAILED ]; then
        progress "$(date +"%Y-%m-%d %H:%M:%S") Successfully finished update"
    else
        progress "$(date +"%Y-%m-%d %H:%M:%S") Update failed due to failing packages!"
    fi

    log "Update end"

) 863>/tmp/insight-toolkit.flock
