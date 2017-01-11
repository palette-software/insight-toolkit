#!/bin/bash

# Stop on first error
set -e

PACKAGEVERSION=${PACKAGEVERSION:-1}
export PACKAGEVERSION

if [ -z "$VERSION" ]; then
    echo "VERSION is missing"
    exit 1
fi

if [ -z "$PACKAGEVERSION" ]; then
    echo "PACKAGEVERSION is missing"
    exit 1
fi

# Prepare for rpm-build
mkdir -p rpm-build
pushd rpm-build
mkdir -p _build

# Create directories
mkdir -p opt/insight-toolkit
mkdir -p var/log/insight-toolkit
mkdir -p var/lib/palette

# Copy the package contents
cp -v ../scripts/* opt/insight-toolkit
cp ../insight-toolkit-cron opt/insight-toolkit

echo "BUILDING VERSION:v$VERSION"

# build the rpm
rpmbuild -bb --buildroot $(pwd) --define "version $VERSION" --define "buildrelease $PACKAGEVERSION" --define "_rpmdir $(pwd)/_build" ../palette-insight-toolkit.spec
popd
