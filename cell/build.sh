#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/cell:$VERSION" .
docker tag -f atlo/cell:$VERSION atlo/cell:latest