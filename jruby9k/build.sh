#!/bin/bash
VERSION=9.0.1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/jruby9k:$VERSION" .
docker tag -f atlo/jruby9k:$VERSION atlo/jruby9k:latest