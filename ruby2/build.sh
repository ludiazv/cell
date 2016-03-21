#!/bin/bash
VERSION=2.2.4
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/ruby2:$VERSION" .
docker tag -f atlo/ruby2:$VERSION atlo/ruby2:latest
docker build $QUIET --force-rm=true --rm=true --tag="atlo/ruby2-alpine:$VERSION" -f Dockerfile.alpine .
docker tag -f atlo/ruby2-alpine:$VERSION atlo/ruby2-alpine:latest
