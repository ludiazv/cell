#!/bin/bash

HN=$(hostname)
SCRIPT=$(basename $0)
WAIT=15
WAITLG=90
DO_LOOP=true

export CELL_LOCAL_IP=$(hostname --ip-address)
echo "$(date -uIseconds) $HN $SCRIPT INFO: PSQL 9.4 container entrypoint starting"

# check if pql has ben initlizized
if [ ! -f $PGDATA/CELL_PG_INIT.txt ]; then
	echo "$(date -uIseconds) $HN $SCRIPT ERROR: PSQL 9.4 data directory is not initilized, run container with --entrypoint='/opt/psql_init.sh' to initialice the DB"
	exit 1
fi

trap "DO_LOOP=false ; /opt/psql_safe_stop.sh ; killall -q confd" HUP INT QUIT KILL TERM EXIT

export CELL_EXEC_TYPE="exec" # Lauch redis server as shell
export CELL_EXEC_PREFIX="gosu postgres" # no prefix
export CELL_EXEC_SLEEP=$WAIT  # wait 5 seconds to start it

while $DO_LOOP; do
	#if not runing postgres start it
	gosu postgres /opt/psqlbin/pg_ctl status > /dev/null 2> /dev/null
	if [ $? -ne 0 ]; then
		echo "$(date -uIseconds) $HN $SCRIPT INFO: PSQL server is stoped, starting it..."
		sleep $WAIT
		/opt/cell_entry.sh '/opt/psqlbin/pg_ctl start'  # Start as daemon
	fi
	
	read -t 60
	
	if [ $? -eq 0 ]; then
		 DO_LOOP=false 
	fi # if input exit loop
done

echo "$(date -uIseconds) $HN $SCRIPT INFO: PSQL 9.4 container has been stopped"