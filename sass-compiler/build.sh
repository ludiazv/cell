#!/bin/bash
VERSION=1.0
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/sass-compiler:$VERSION" .
docker tag atlo/sass-compiler:$VERSION atlo/sass-compiler:latest
