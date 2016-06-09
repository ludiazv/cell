#!/bin/bash
VERSION=1.0
VERSIONTWO=2.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/registry:$VERSION" .
#docker tag -f atlo/registry:$VERSION atlo/registry:latest
docker build $QUIET --force-rm=true --rm=true --tag="atlo/registry:$VERSIONTWO" -f Dockerfile.v2 .
docker tag atlo/registry:$VERSIONTWO atlo/registry:latest
