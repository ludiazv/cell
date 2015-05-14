#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/ruby2:$VERSION" .
docker tag -f atlo/ruby2:$VERSION atlo/ruby2:latest