#!/bin/sh
source /etc/environment
PREFIX="/psql_test/"

MPWD=$(pwd)

# Clean and repopulate ETCD
cd ../etcd-yaml/
./run.sh --yes -p $PREFIX --recursive delete
cat $MPWD/sample_etcd.yml | ./run.sh --yes -p $PREFIX -k /opt/keys/public.gpg import
#echo "loaded ETCD..."
#./run.sh -p $PREFIX
cd $MPWD

# Pre Init phase -> Create users and volume on host
sudo mkdir -p /opt/psql-data
sudo mkdir -p /opt/psql-backup
id -u postgres &> /dev/null
if [ $? -eq 1 ] ; then
	MGID=$(docker run -t --rm --name psql-usr --entrypoint='/opt/psql_gid.sh' atlo/psql94)
	MUID=$(docker run -t --rm --name psql-usr --entrypoint='/opt/psql_uid.sh' atlo/psql94)
    echo "Creating postgres account on host $MUID/$MGID"
	sudo groupadd -g $MGID postgres
	sudo useradd -r -u $MUID -g postgres postgres
fi
sudo chown -R postgres:postgres /opt/psql-data
sudo chown -R postgres:postgres /opt/psql-backup


# Init phase -> Inititate the DB
# - test file existence as root as folder psql-data is protected if initilized
sudo test -f /opt/psql-data/PG_VERSION 
if [ $? -eq 1 ] ; then
    sudo rm -fr /opt/psql-data
    sudo mkdir -p /opt/psql-data
    sudo chown -R postgres:postgres /opt/psql-data
	docker  run -t -i --rm --name psql-init \
		 	--entrypoint='/opt/psql_init.sh' \
		 	-v /opt/psql-data:/opt/psql-data \
		 	-v /opt/keyring:/opt/keyring \
            -v $(realpath ../etcd-yaml):/opt/keys \
		 	-e CELL_ETCD_NODE="http://${COREOS_PRIVATE_IPV4}:2379" \
		 	-e CELL_PSQL_CONFIG="${PREFIX}psql/credentials" \
            -e CELL_SECRET_FILE="/opt/keys/secret.gpg" atlo/psql94
else
    # run the service
    docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} \
    	-p ${COREOS_PRIVATE_IPV4}:5432:5432  --name psql94 \
        -v /opt/psql-data:/opt/psql-data \
        -v /opt/psql-backup:/opt/psql-backup \
        atlo/psql94
fi	



#if [ "$1" = "initdb" ]; then
#	# run contanienr in init mode
#	docker run -i --rm -t --volumes-from="psql94-data-vol" --name psql94-init --entrypoint="/opt/psql_init.sh" -p ${COREOS_PRIVATE_IPV4}:5433:5432 atlo/psql94
#else
#	# run container in run mode
#	docker run -i --rm -t -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} \
#	-p ${COREOS_PRIVATE_IPV4}:5432:5432  --name psql94 --volumes-from="psql94-data-vol" \
#   atlo/psql94
#fi