#!/bin/bash
echo "Building PSQL..."
VERSION=9.5
QUIET=-q
docker build $QUIET --force-rm=true --rm=true --tag="atlo/psql:9.4" -f Dockerfile-9.4 .
docker build $QUIET --force-rm=true --rm=true --tag="atlo/psql:$VERSION" -f Dockerfile-$VERSION .
docker tag atlo/psql:$VERSION atlo/psql:latest
