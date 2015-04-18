#!/bin/sh
source /etc/environment
PREFIX="/"
./create_datavol.sh
#docker run -d -e HOST_IP=${COREOS_PRIVATE_IPV4} -p ${COREOS_PRIVATE_IPV4}:6379:6379 --privileged --name redis --volumes-from=redis-data-vol atlo/redis28
docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} -p ${COREOS_PRIVATE_IPV4}:6379:6379 --privileged --name redis --volumes-from=redis-data-vol atlo/redis28