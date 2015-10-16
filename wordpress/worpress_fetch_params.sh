#!/bin/bash

# Set secret file if not provided
[ -z "$CELL_SECRET_FILE" ] && CELL_SECRET_FILE="/opt/keyring/.secret.gpg"

# Step 1. Get credentials and store it in env variables
echo "Fetching congiguration from ETCD ${CELL_ETCD_NODE} -> $CELL_MYSQL_CONFIG using ${CELL_SECRETFILE} as key"
t=$(etcdctl --endpoint="$CELL_ETCD_NODE" --no-sync get ${CELL_MYSQL_CONFIG}/db)
[ $? -eq 0 ] && export CELL_DB="$t"
t=$(etcdctl --endpoint="$CELL_ETCD_NODE" --no-sync get ${CELL_MYSQL_CONFIG}/db-user)
[ $? -eq 0 ] && export CELL_USER="$t"
t=$(crypt get -endpoint="$CELL_ETCD_NODE" -secret-keyring="${CELL_SECRET_FILE}" ${CELL_MYSQL_CONFIG}/db-user-pwd)
[ $? -eq 0 ] && export CELL_PWD=$t

if [ -z "$CELL_DB" ] || [ -z "$CELL_USER" ] || [ -z "$CELL_PWD" ] ; then
	echo "ERROR: CELL_DB, CELL_USER or CELL_PWD could not be read from etcd."
	exit 1
fi
exit 0