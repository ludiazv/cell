#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/redis28:$VERSION" .
docker tag -f atlo/redis28:$VERSION atlo/redis28:latest