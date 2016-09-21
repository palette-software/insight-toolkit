#!/bin/bash

LOCKFILE=/tmp/PI_LoadCTRL.flock
LOGFILE="/var/log/insight-toolkit/loadctrl.log"
LAST_RUN_TS_FILE="/var/lib/palette/loadctrl_last_maintenance_ts"
DBLOGFILE="/var/log/insight-toolkit/db_maintenance.log"

set -e

(
    # Pick an arbitrary file descriptor number. You can pick anything, but by default the limit of the
    # maximum open file descriptors is 1024. And the selected file descriptor must be lower than the limit,
    # otherwise the flock command will fail.
    flock -n 768

    if [ ! -e ${LAST_RUN_TS_FILE} ]
    then
        echo 10010101 00:00:01 > ${LAST_RUN_TS_FILE}
    fi

    LAST_MAINTENANCE_TS=$(cat ${LAST_RUN_TS_FILE})
    currtime=$(date)
	#UTC 09:00 is 02:00 in USA SF time
    maintenance_after=0900

	#Check if current time has passed the maintenece time and there has been NO maintenance in that day yet.
    if [ $(date -d "$currtime" +"%H%M") -gt $maintenance_after -a $(date -d "$currtime" +"%Y%m%d") -gt $(date -d "${LAST_MAINTENANCE_TS}" +"%Y%m%d") ]
    then
        echo Last maintenance run was at $(date -d "${LAST_MAINTENANCE_TS}" +"%Y.%m.%d. %H:%M:%S") >> $LOGFILE
        echo "Start maintenance... $(date)" >> $LOGFILE
        sudo /opt/insight-toolkit/cleanup_insight_server_archive.sh >> ${LOGFILE}
        sudo -i -u gpadmin /opt/insight-toolkit/cleanup_db_log.sh >> ${LOGFILE}
        sudo -i -u gpadmin /opt/insight-toolkit/db_maintenance.sh > ${DBLOGFILE}
        echo "End maintenance $(date)" >> $LOGFILE
        date -d "$currtime" +"%Y%m%d %H:%M:%S" > ${LAST_RUN_TS_FILE}
    else
        echo "Start reporting... $(date)" >> $LOGFILE
        /opt/insight-reporting-framework/run_reporting.sh
        echo "End reporting $(date)" >> $LOGFILE		
    fi
) 768>${LOCKFILE}
