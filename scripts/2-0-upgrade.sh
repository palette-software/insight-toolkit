#!/bin/bash

sudo service supervisord restart
sudo supervisorctl restart palette-insight-gpfdist
sudo supervisorctl restart palette-insight-server

