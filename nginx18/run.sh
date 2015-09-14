#!/bin/sh
source /etc/environment
PREFIX="/"
docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} \
		-p ${COREOS_PRIVATE_IPV4}:80:80 -p ${COREOS_PRIVATE_IPV4}:443:443 --privileged --name nginx atlo/nginx16