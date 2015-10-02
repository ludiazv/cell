#!/bin/bash
VERSION=1.0
QUIET= --quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/mysql:$VERSION" .
docker tag -f atlo/mysql:$VERSION atlo/mysql:latest