#!/bin/bash
VERSION=1.0
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/mysql:$VERSION" .
docker tag -f atlo/mysql:$VERSION atlo/mysql:latest