#!/bin/bash
set -e
SUP="gosu postgres"
PG_CTL="$SUP /opt/psqlbin/pg_ctl"
PSQL="$SUP /opt/psqlbin/psql"

echo "PSQL INITDB on $PGDATA ...."
echo "----------------------------------"

# Set secret file if not provided
[ -z "$CELL_SECRET_FILE" ] && CELL_SECRET_FILE="/opt/keyring/.secret.gpg"

# Get config from configfile
if [ -n "$CELL_PSQL_CONFIG" ] ; then
	echo "Fetching congiguration from ETCD ${CELL_ETCD_NODE} -> $CELL_PSQL_CONFIG using ${CELL_SECRET_FILE} as key"
	t=$(etcdctl --endpoint="$CELL_ETCD_NODE" --no-sync get ${CELL_PSQL_CONFIG}/db)
	[ $? -eq 0 ] && CELL_DB=$t
	t=$(etcdctl --endpoint="$CELL_ETCD_NODE" --no-sync get ${CELL_PSQL_CONFIG}/db-user)
	[ $? -eq 0 ] && CELL_USER=$t
	t=$(crypt get -endpoint="$CELL_ETCD_NODE" -secret-keyring="${CELL_SECRET_FILE}" ${CELL_PSQL_CONFIG}/db-user-pwd)
	[ $? -eq 0 ] && CELL_PWD=$t
else
	echo "Using configuration form ENV Variables..."
fi

[ -z "$CELL_DB" ] && CELL_DB="cell"
[ -z "$CELL_USER" ] && CELL_USER="cell"
[ -z "$CELL_PWD" ] && CELL_PWD="cell"



$PG_CTL initdb -o '--encoding=UTF8'
if [ $? -eq 0 ]; then
	# start server
	$PG_CTL start
	sleep 5
	$PG_CTL status
	# secure postgres user with a random 32char password.
	$PSQL -c "ALTER USER postgres WITH PASSWORD '$(openssl rand -base64 32)';"
	# create user provide
	echo "Also creating user: $CELL_USER and DB: $CELL_DB"
	echo "-----------------------------------------------------"
	$SUP /opt/psqlbin/createdb --template=template0 --encoding='utf-8' $CELL_DB
	$PSQL -c "CREATE EXTENSION IF NOT EXISTS hstore;"
	$PSQL -c "CREATE EXTENSION IF NOT EXISTS plpgsql;"
	$PSQL -c "CREATE ROLE $CELL_USER NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD '$CELL_PWD';"
	$PSQL -c "ALTER DATABASE $CELL_DB OWNER TO $CELL_USER;"
	$PSQL -c "grant all privileges on database $CELL_DB to $CELL_USER ;"
	#$PSQL -c "\l;"
	#$PSQL -c "\du;"
	echo "-----------------------------------------------------"
	echo "Sleeping for stability..."
	sleep 5
	set +e
	echo "Stoping server in gracefully mode..."
	$PG_CTL stop -t 10 -m fast
	[ $? -ne 0 ] && echo "Force shutdown of server ..." && $PG_CTL stop -t 20 -m immediate
	sleep 5
  echo "Data container initializaed at $(date -uIseconds) DB=$CELL_DB USER=$CELL_USER" > $PGDATA/CELL_PG_INIT.txt
	set +e  # avoid error interrupt
  $PG_CTL status
else
    #report error
    exit 1
fi

echo "PSQL INITDB on $PGDATA .... finished!"
echo "------------------------------------------"
exit 0
