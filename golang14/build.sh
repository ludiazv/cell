#!/bin/bash
VERSION=1.0
QUIET=
docker build $QUIET --force-rm=true --rm=true --tag="atlo/golang14:$VERSION" .
docker tag -f atlo/golang14:$VERSION atlo/golang14:latest