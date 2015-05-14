#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/rails42:$VERSION" .
docker tag -f atlo/rails42:$VERSION atlo/rails42:latest