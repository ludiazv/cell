#!/bin/sh
source /etc/environment
PREFIX="/"
./create_datavol.sh
if [ "$1" = "initdb" ]; then
	# run contanienr in init mode
	docker run -i --rm -t --volumes-from="psql94-data-vol" --name psql94-init --entrypoint="/opt/psql_init.sh" -p ${COREOS_PRIVATE_IPV4}:5433:5432 atlo/psql94
else
	# run container in run mode
	docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} \
	-p ${COREOS_PRIVATE_IPV4}:5432:5432  --name psql94 --volumes-from="psql94-data-vol" \
    atlo/psql94
fi