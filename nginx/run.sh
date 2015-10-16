#!/bin/sh
source /etc/environment
PREFIX="/nginx_test/"
cd ../etcd-yaml
./run.sh --yes -p $PREFIX --recursive delete
cat sample_etcd.yml | ./run.sh --yes -p $PREFIX import
cd ../nginx
docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} \
		-p ${COREOS_PRIVATE_IPV4}:80:80 -p ${COREOS_PRIVATE_IPV4}:443:443 \
        --name nginxatlo/nginx