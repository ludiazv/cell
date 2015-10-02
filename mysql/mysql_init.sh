#!/bin/bash
set -e

MYSQL_DATA="/opt/mysql-data"

# check if pql has ben initlizized
if [ -f $MYSQL_DATA/mysql_cell_init.txt ] ; then
	echo " $SCRIPT ERROR: MYSQL is initialized"
	exit 1
fi

echo "MySQL DB Setup......"
echo "===================="

[ -z "$CELL_DB" ] 		&& CELL_DB="cell"
[ -z "$CELL_USER" ] 	&& CELL_USER="cell"
[ -z "$CELL_PWD" ] 		&& CELL_PWD="cell"
[ -z "$CELL_ROOT_PWD" ] && CELL_ROOT_PWD="cell_root_pwd"

# init the DB
echo 'Running mysql_install_db'
mysql_install_db --user=mysql --datadir="/opt/mysql-data" --rpm --keep-my-cnf
echo 'Finished mysql_install_db'

# Configure basic service
#echo "mysqld --user=mysql --datadir="${MYSQL_DATA}" --skip-networking &"
echo "Starting MSQLD...."
mysqld --user=mysql --datadir=/opt/mysql-data --skip-networking &
pid="$!"
sleep 3

mysql=( mysql --protocol=socket -uroot )
for i in {30..0}; do
	if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
		echo "Mysqld is UP!"
		break
	fi
	echo 'MySQL init process in progress...'
	ps xa
	sleep 1
done
if [ "$i" = 0 ]; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi
echo "Executing init SQL..."
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
	FLUSH PRIVILEGES ;
EOSQL

if ! kill -s TERM "$pid" || ! wait "$pid"; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi

echo "done!"
touch $MYSQL_DATA/mysql_cell_init.txt
echo $(date) > $MYSQL_DATA/mysql_cell_init.txt
chown -R mysql:mysql ${MYSQL_DATA}
echo "MySql init process finished!"
echo "============================"

exit 0
