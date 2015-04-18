#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/psql94:$VERSION" .
docker tag -f atlo/psql94:$VERSION atlo/psql94:latest