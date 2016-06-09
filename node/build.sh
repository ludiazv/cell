#!/bin/bash
VERSION=6.2
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/node:$VERSION" .
docker tag atlo/node:$VERSION atlo/node:latest
