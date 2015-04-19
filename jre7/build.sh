#!/bin/bash
VERSION=1.0
QUIET=
docker build $QUIET --force-rm=true --tag="atlo/jre7:$VERSION" .
docker tag -f atlo/jre7:$VERSION atlo/jre7:latest