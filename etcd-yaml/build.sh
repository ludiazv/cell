#!/bin/bash
VERSION=1.0
QUIET=--quiet
docker build $QUIET --force-rm=true --rm=true --tag="atlo/etcd-yaml:$VERSION" .
docker tag -f atlo/etcd-yaml:$VERSION atlo/etcd-yaml:latest