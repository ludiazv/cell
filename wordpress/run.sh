#!/bin/sh
source /etc/environment
PREFIX="/wordpress_test/"
cd ../etcd-yaml
./run.sh --yes -p $PREFIX --recursive delete
cat ../wordpress/sample_etcd.yml | ./run.sh --yes -p $PREFIX -k /opt/keys/public.gpg import
./run.sh -p $PREFIX 
cd ../wordpress
docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} \
		-e CELL_ETCD_PREFIX=${PREFIX} \
		-e CELL_SECRET_FILE="/opt/keys/secret.gpg" \
		-p ${COREOS_PRIVATE_IPV4}:80:80 -p ${COREOS_PRIVATE_IPV4}:443:443 --name wordpress \
		-v $(realpath ../etcd-yaml):/opt/keys \
		atlo/wordpress