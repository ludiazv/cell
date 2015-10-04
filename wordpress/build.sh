#!/bin/bash
VERSION=4.3
#QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/wordpress:$VERSION" .
docker tag -f atlo/wordpress:$VERSION atlo/wordpress:latest