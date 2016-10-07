#!/bin/bash

(

    LOADTABLES_LOCKFILE=/tmp/PI_ImportTables_prod.flock
    flock $LOADTABLES_LOCKFILE

# Wait with flock for the loadtables to finish
flock ${LOADTABLES_LOCKFILE} echo "<-- Loadtables finished"

) 863>/tmp/insight-toolkit.flock
