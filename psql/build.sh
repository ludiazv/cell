#!/bin/bash
VERSION=9.5
QUIET=-q
docker build $QUIET --force-rm=true --rm=true --tag="atlo/psql:$VERSION" .
docker tag atlo/psql:$VERSION atlo/psql:latest
