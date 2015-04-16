#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/nginx16:$VERSION" .
docker tag -f atlo/nginx16:$VERSION atlo/nginx16:latest