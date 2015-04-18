#!/bin/bash
VERSION=1.0
QUIET=-q
docker build $QUIET --force-rm=true --tag="atlo/cassandra20:$VERSION" .
docker build $QUIET --force-rm=true --tag="atlo/cassandra20:latest"   .