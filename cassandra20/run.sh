#!/bin/sh
source /etc/environment
MIP=${COREOS_PRIVATE_IPV4}
HN=$(hostname)
PREFIX="/"

#docker run -t -i --rm --name="cas" -e HOST_IP=$MIP -e IS_SEED=$SED -e HOST_NAME=$HN -p ${MIP}:9000:9000 -p ${MIP}:7199:7199 -p ${MIP}:9042:9042 -p ${MIP}:9160:9160 -p ${MIP}:61621:61621 --net=host atlo/cassandra20
#docker run -t -i --rm --name="cas" -e HOST_IP=$MIP -e IS_SEED=$SED -P atlo/cassandra2	   

./create_datavol.sh
if [ "$1" = "initdb" ]; then
	# run contanienr in init mode
	docker run -i --rm -t --volumes-from="cas-data-vol" --name cas-init --entrypoint="/opt/cassandra_init.sh" \
	-e HOST_IP=$MIP -e HOST_NAME=$HN -e CELL_ETCD_PREFIX=${PREFIX} \
	-p ${MIP}:9000:9000 -p ${MIP}:9001:9001 -p ${MIP}:7199:7199 -p ${MIP}:9042:9042 -p ${MIP}:9160:9160  -p ${MIP}:61621:61621 \
	--net=host atlo/cassandra20
else
	# run container in run mode
	docker run -i --rm -t --volumes-from="cas-data-vol" --name="cas"  \
	-e HOST_IP=$MIP -e HOST_NAME=$HN -e CELL_ETCD_PREFIX=${PREFIX} \
	-p ${MIP}:9000:9000 -p ${MIP}:9001:9001 -p ${MIP}:7199:7199 -p ${MIP}:9042:9042 -p ${MIP}:9160:9160  -p ${MIP}:61621:61621 \
	--net=host atlo/cassandra20
fi