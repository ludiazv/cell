#!/bin/sh
SUP="gosu postgres"
PG_CTL="$SUP /opt/psqlbin/pg_ctl"
PSQL="$SUP /opt/psqlbin/psql"

[ -z "$CELL_DB" ] && CELL_DB="cell"
[ -z "$CELL_USER" ] && CELL_USER="cell"
[ -z "$CELL_PWD" ] && CELL_PWD="cell"

echo "PSQL INITDB on $PGDATA ...."
echo "----------------------------------"

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
	$PSQL -c "CREATE EXTENSION hstore;"
	$PSAL -c "CREATE EXTENSION plpgsql;"
	$PSQL -c "CREATE ROLE $CELL_USER NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD '$CELL_PWD';"
	$PSQL -c "ALTER DATABASE $CELL_DB OWNER TO $CELL_USER;"
	$PSQL -c "grant all privileges on database $CELL_DB to $CELL_USER"
	$PSQL -c "\l"
	$PSQL -c "\du"
	$PG_CTL stop -m fast
	sleep 5
	$PG_CTL status
	echo "Data container initializaed at $(date -uIseconds) DB=$CELL_DB USER=$CELL_USER" > $PGDATA/CELL_PG_INIT.txt
fi
