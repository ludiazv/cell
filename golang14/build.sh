#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/golang14:$VERSION" .
docker tag atlo/golang14:$VERSION atlo/golang14:latest
