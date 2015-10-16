#!/bin/sh
source /etc/environment
PREFIX="/mysql_test/"

cd ../etcd-yaml/
./run.sh --yes -p $PREFIX --recursive delete
cat ../mysql/sample_etcd.yml | ./run.sh --yes -p $PREFIX -k /opt/keys/public.gpg import
cd ../mysql/

sudo mkdir -p /opt/mysql-data
id -u mysql &> /dev/null
if [ $? -eq 1 ] ; then
	new group_cmd=$(docker run -it --rm --name mysql-usr --entrypoint='/opt/mysql_addgroup.sh' atlo/mysql)
	new_user_cmd=$(docker run -it --rm --name mysql-usr --entrypoint='/opt/mysql_adduser.sh' atlo/mysql)
	sudo groupadd -g 2016 mysql
	sudo useradd -r -u 2016 -g mysql mysql
fi
sudo chown -R mysql:mysql /opt/mysql-data

if [ ! -f /opt/mysql-data/mysql_cell_init.txt ] ; then
    sudo rm -fr /opt/mysql-data
    sudo mkdir -p /opt/mysql-data
    sudo chown -R mysql:mysql /opt/mysql-data
	docker  run -it --rm --name mysql-init \
		 	--entrypoint='/opt/mysql_init.sh' \
		 	-v /opt/mysql-data:/opt/mysql-data \
		 	-v /opt/keyring:/opt/keyring \
            -v $(realpath ../etcd-yaml):/opt/keys \
		 	-e CELL_ETCD_NODE="http://${COREOS_PRIVATE_IPV4}:2379" \
		 	-e CELL_MYSQL_CONFIG="${PREFIX}mysql/credentials" \
            -e CELL_SECRET_FILE="/opt/keys/secret.gpg" atlo/mysql
else
	docker run -i --rm -t -p ${COREOS_PRIVATE_IPV4}:3306:3306 --name mysql \
		 -e HOST_IP=${COREOS_PRIVATE_IPV4} -e CELL_ETCD_PREFIX=${PREFIX} \
		 -e CELL_ETCD_NODE="http://${COREOS_PRIVATE_IPV4}:2379" \
		 -v /opt/mysql-data:/opt/mysql-data \
		 atlo/mysql
fi		
