#!/bin/bash
VERSION=1.0
QUIET= --quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/memcached:$VERSION" .
docker tag -f atlo/memcached:$VERSION atlo/memcached:latest
