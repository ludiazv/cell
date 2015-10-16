#!/bin/bash
source /etc/environment
docker run --rm -i --name etcd-yaml-run -e CELL_NO_BANNER="y" -v $(realpath .):/opt/keys atlo/etcd-yaml " -C http://${COREOS_PRIVATE_IPV4}:2379 $@" 