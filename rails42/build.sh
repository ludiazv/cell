#!/bin/bash
VERSION=4.2.1
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/rails42:$VERSION" .
docker tag -f atlo/rails42:$VERSION atlo/rails42:latest