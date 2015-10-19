#!/bin/bash

# Include cell param checks and etcd functions
source /opt/cell_functions.sh

# Step 1. Get credentials and store it in env variables
function fetch_mysql {
echo "Fetching wordpress DB configuration from ETCD ${CELL_ETCD_NODE} in ${CELL_ETCD_PREFIX} using ${CELL_SECRET_FILE} as key"
etcdctl_present "wordpress_conf/mysql-type"
if [ $? -eq 0 ] ; then
	local mtype=$(etcdctl_get "wordpress_conf/mysql-type" "static")
	case "$mtype" in
		static)
			echo "Configuring wordpress container as static..."
			export CELL_DB_IP=$(etcdctl_get "wordpress_conf/mysql-static-ip" "$HOST_IP" )
			export CELL_DB=$(etcdctl_get "wordpress_conf/mysql-static-db" "$CELL_DB")
			export CELL_USER=$(etcdctl_get "wordpress_conf/mysql-static-user" "$CELL_DB")
			export CELL_DB_PORT=$(etcdctl_get "wordpress_conf/mysql-static-port" "3306")
			export CELL_PWD=$(crypt_get "wordpress_conf/mysql-static-pwd" "$CELL_PWD")
			;;
		dynamic)
			echo "Configuring wordpress container as dynamic"
			echo "TODO..."	
			;;
		*)
		   echo "ERROR: mysql-type confirguration mode $mtype not suported."
		   ;;
	esac
else
	echo "ERROR: ETCD param wordpress_conf/mysql-type not present. This configuration parameter is mandatory to continue."
	return 1 
fi

# Final check
if [ -z "$CELL_DB_IP" ] || [ -z "$CELL_DB" ] || [ -z "$CELL_USER" ] || [ -z "$CELL_PWD" ] ; then
	echo "ERROR: CELL_DB_IP, CELL_DB, CELL_USER or CELL_PWD could not be read from etcd."
	return 1
fi

echo "DEBUG: DB info CELL_DB_IP:$CELL_DB_IP and $CELL_DB_PORT , CELL_DB: $CELL_DB , CELL_USER:$CELL_USER , CELL_PWD:$CELL_PWD"
return 0
}