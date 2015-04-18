#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/registry:$VERSION" .
docker tag -f atlo/registry:$VERSION atlo/registry:latest
