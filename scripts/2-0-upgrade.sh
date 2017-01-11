#!/bin/bash

sudo supervisorctl stop insight-gpfdist
sudo supervisorctl stop palette-insight-server
# Change the directory name from the name of the tenant to palette
# It made rpm installation tenant independent
mv /data/insight-server/uploads/`ls -l /data/insight-server/uploads/ | grep -v "_temp" | tr -s ' ' | cut -d' ' -f9 | tail -1` /data/insight-server/uploads/palette
