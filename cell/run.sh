#!/bin/sh
source /etc/environment
PREFIX="/"
#docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} --name cell atlo/cell
docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} --name cell atlo/cell-alpine
