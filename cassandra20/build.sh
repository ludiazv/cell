#!/bin/bash
VERSION=1.0
QUIET=-q
docker build $QUIET --force-rm=true --tag="atlo/cassandra20:$VERSION" .
docker tag -f atlo/cassandra20:$VERSION atlo/cassandra20:latest