#!/bin/bash
VERSION=9.1.2.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/jruby9k:$VERSION" .
docker tag atlo/jruby9k:$VERSION atlo/jruby9k:latest
docker build $QUIET --force-rm=true --rm=true --tag="atlo/jruby9k-alpine:$VERSION" -f Dockerfile.alpine .
docker tag atlo/jruby9k-alpine:$VERSION atlo/jruby9k-alpine:latest
