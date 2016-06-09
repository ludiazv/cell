#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --tag="atlo/jre7:$VERSION" .
docker tag atlo/jre7:$VERSION atlo/jre7:latest
