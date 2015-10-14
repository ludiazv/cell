#!/bin/bash
set -e

MYSQL_DATA="/opt/mysql-data"

# check if pql has ben initlizized
if [ -f $MYSQL_DATA/mysql_cell_init.txt ] ; then
	echo " $SCRIPT MYSQL is initialized. Nothing done!"
	exit 0
fi

echo "MySQL DB Setup......"
echo "===================="

# Get config from configfile
if [ -n "$CELL_MYSQL_CONFIG" ] ; then
	echo "Fetching congiguration from ETCD ${CELL_ETCD_NODE} -> $CELL_MYSQL_CONFIG"
	t=$(etcdctl --endpoint="$CELL_ETCD_NODE" --no-sync get ${CELL_MYSQL_CONFIG}/db)
	[ $? -eq 0 ] && CELL_DB=$t
	t=$(etcdctl --endpoint="$CELL_ETCD_NODE" --no-sync get ${CELL_MYSQL_CONFIG}/db-user)
	[ $? -eq 0 ] && CELL_USER=$t
	t=$(crypt get -endpoint="$CELL_ETCD_NODE" -secret-keyring="/opt/keyring/.secret.gpg" ${CELL_MYSQL_CONFIG}/db-user-pwd)
	[ $? -eq 0 ] && CELL_PWD=$t
	t=$(crypt get -endpoint="$CELL_ETCD_NODE" -secret-keyring="/opt/keyring/.secret.gpg" ${CELL_MYSQL_CONFIG}/db-root-pwd)
	[ $? -eq 0 ] && CELL_ROOT_PWD=$t
	t=$(crypt get -endpoint="$CELL_ETCD_NODE" -secret-keyring="/opt/keyring/.secret.gpg" ${CELL_MYSQL_CONFIG}/db-bkup-pwd)
	[ $? -eq 0 ] && CELL_BKUP_PWD=$t
else
	echo "Using configuration form ENV Variables..."
fi

[ -z "$CELL_DB" ] 		&& CELL_DB="cell"
[ -z "$CELL_USER" ] 	&& CELL_USER="cell"
[ -z "$CELL_PWD" ] 		&& CELL_PWD="cell"
[ -z "$CELL_ROOT_PWD" ] && CELL_ROOT_PWD="cell_root_pwd"
[ -z "$CELL_BKUP_PWD" ] && CELL_BKUP_PWD="cell_bkup_pwd"

# init the DB
sed -i "s/^\(datadir.*=\).*/\1\/opt\/mysql-data/" /etc/mysql/my.cnf
sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
rm -fr /opt/mysql-data/*
mkdir -p /opt/mysql-data
chown -R mysql:mysql /opt/mysql-data

echo 'Running mysql_install_db'
mysql_install_db --user=mysql --datadir="/opt/mysql-data" #--rpm --keep-my-cnf
echo 'Finished mysql_install_db'

# Configure basic service
#echo "mysqld --user=mysql --datadir="${MYSQL_DATA}" --skip-networking &"
# init the DB
sed -i "s/^\(datadir.*=\).*/\1\/opt\/mysql-data/" /etc/mysql/my.cnf
sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
sleep 2
echo "Starting MSQLD...."
mysqld --user=mysql --skip-networking &
pid="$!"

sleep 2

mysql=( mysql --protocol=socket -uroot )

for i in {30..0}; do
	if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
		echo "Mysqld is UP!"
		break
	fi
	echo 'MySQL init process in progress...'
	sleep 1
done
if [ "$i" = 0 ]; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi
echo "Running MYSQL Tunner..."
cd /opt
#perl mysqltuner.pl --buffers --dbstat --idxstat --outputfile result_mysqltuner.txt
/bin/bash

echo "Executing init SQL..."
#echo "CELL_DB=$CELL_DB,CELL_USER=$CELL_USER,CELL_ROOT_PWD=$CELL_ROOT_PWD,CELL_BKUP_PWD=$CELL_BKUP_PWD"
"${mysql[@]}" <<-EOSQL
	-- What's done in this file shouldn't be replicated
	--  or products like mysql-fabric won't work
	SET @@SESSION.SQL_LOG_BIN=0;
	DELETE FROM mysql.user ;
	CREATE USER 'root'@'%' IDENTIFIED BY  '${CELL_ROOT_PWD}' ;
	GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
	DROP DATABASE IF EXISTS test ;
	CREATE DATABASE IF NOT EXISTS  \`${CELL_DB}\` ;
	CREATE USER '${CELL_USER}'@'%' IDENTIFIED BY '${CELL_PWD}' ;
	GRANT ALL ON  \`${CELL_DB}\`.* TO '${CELL_USER}'@'%' ;
	CREATE USER \`bckup\`@\`localhost\` IDENTIFIED BY '${CELL_BKUP_PWD}';
	GRANT SHOW DATABASES, SELECT, LOCK TABLES, RELOAD ON *.* TO \`bckup\`@\`localhost\`;
	FLUSH PRIVILEGES ;
EOSQL



if ! kill -s TERM "$pid" || ! wait "$pid"; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi

echo "done init db!"
#touch $MYSQL_DATA/mysql_cell_init.txt
echo "Writing cell siganture files..."
echo $(date) > $MYSQL_DATA/mysql_cell_init.txt
[ -n "$CELL_MYSQL_CONFIG" ] && echo "$CELL_MYSQL_CONFIG" > $MYSQL_DATA/mysql_cell_credentials_key.txt
chown -R mysql:mysql ${MYSQL_DATA}
echo "MySql init process finished!"
echo "============================"
exit 0
