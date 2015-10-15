#!/bin/bash
VERSION=1.8
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/nginx:$VERSION" .
docker tag -f atlo/nginx:$VERSION atlo/nginx:latest