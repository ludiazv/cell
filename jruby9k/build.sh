#!/bin/bash
VERSION=9.0.5.0
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/jruby9k:$VERSION" .
docker tag -f atlo/jruby9k:$VERSION atlo/jruby9k:latest
docker build $QUIET --force-rm=true --rm=true --tag="atlo/jruby9k-alpine:$VERSION" -f Dockerfile.alpine .
docker tag -f atlo/jruby9k-alpine:$VERSION atlo/jruby9k-alpine:latest
