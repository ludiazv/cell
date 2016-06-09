#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/cell:$VERSION" .
docker tag atlo/cell:$VERSION atlo/cell:latest
docker build $QUIET --force-rm=true --rm=true --tag="atlo/cell-alpine:$VERSION" -f Dockerfile.alpine .
docker tag atlo/cell-alpine:$VERSION atlo/cell-alpine:latest
