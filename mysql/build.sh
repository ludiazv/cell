#!/bin/bash
VERSION=5.5
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/mysql:$VERSION" .
docker tag "atlo/mysql:$VERSION" atlo/mysql:latest
