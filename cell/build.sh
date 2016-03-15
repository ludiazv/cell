#!/bin/bash
VERSION=1.0
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/cell:$VERSION" .
docker tag -f atlo/cell:$VERSION atlo/cell:latest
docker build $QUIER --force-rm=true --rm=true --tag="atlo/cell-alpine:$VERSION" -f Dockerfile.alpine .
docker tag -f atlo/cell-alpine:$VERSION atlo/cell-alpine:latest
