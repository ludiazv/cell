#!/bin/bash
SCRIPT=$(basename $0)
WAIT=10
WAITLG=90

export MYSQL_DATA="/opt/mysql-data"

export CELL_LOCAL_IP=$(hostname --ip-address)
export CELL_EXEC_TYPE="shell" # Lauch in process
export CELL_EXEC_PREFIX="/bin/sh -c" # no prefix
export CELL_EXEC_BACKGROUND="&" # in background
export CELL_EXEC_SLEEP=$WAIT  # wait 5 seconds to start it

# check if pql has ben initlizized
if [ ! -f $MYSQL_DATA/mysql_cell_init.txt ]; then
	echo "$SCRIPT ERROR: MYSQL not initlizized please run the container with --entrypoint=/opt/mysql_init.sh"
	exit 1
fi

# Bind local IP - Now done by confd
#sed -i "s/^\(bind-address.*=\).*/\1${CELL_LOCAL_IP}/" /etc/mysql/my.cnf

trap "echo 'Trap finishing'; DO_LOOP=false ; killall -q mysqld ; killall -q confd" HUP INT QUIT KILL TERM EXIT

while $DO_LOOP; do
	pid=$(pidof mysqld)
	if [ $? -eq 0 ] ; then
		# Process is running....
		read -t 90 # nothing to do.
	else
		echo "Starting MySql...."
		/opt/cell_entry.sh \'exec mysqld ${MYSQL_OPTIONS}\'
		sleep 2
		echo "INFO: MySql started with pid $(pidof mysqld)"
	fi
	sleep $WAIT
done