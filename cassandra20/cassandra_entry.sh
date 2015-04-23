#!/bin/sh
HN=$(hostname)
SCRIPT=$(basename $0)
WAIT=10
DO_LOOP=true

echo "$(date -uIseconds) $HN $SCRIPT INFO: CASSANDRA 2.0 container entrypoint starting"
# check if pql has ben initlizized
if [ ! -f /opt/cassandra-data/CELL_CASS_INIT.txt ]; then
	echo "InitDB cell casandra DB"
	/opt/cassandra_init.sh
fi
# As this container uses host network we include the name of the host and IP in host for name resulution.
# this is requied for cassandra's gossip startup
echo "$(date -uIseconds) $HN $SCRIPT INFO: configuring /etc/hosts"
echo "$HOST_IP $HOST_NAME" >> /etc/hosts
# Exporting variables
export CQLSH_HOST=$HOST_IP
export CQLSH_PORT=9160
export CELL_LOCAL_IP=$HOST_IP
# Set variables for using cell_entry.sh
export CELL_EXEC_TYPE="exec" # Lauch redis server as shell
export CELL_EXEC_PREFIX="gosu cassandra " # as redis
export CELL_EXEC_SLEEP=$WAIT  # wait 5 seconds to start it

trap "DO_LOOP=false; killall -q java ; killall -q confd" HUP INT QUIT KILL TERM EXIT

while $DO_LOOP; do
	/opt/cell_entry.sh /opt/cassandra/bin/cassandra -f -p /opt/cassandra_pid.pid
	if [ -f "/opt/cassandra_restart.txt" ] ; then
		DO_LOOP=true
		rm -f /opt/cassandra_restart.txt
	else
		DO_LOOP=false
	fi
done
echo "$(date -uIseconds) $HN $SCRIPT INFO: CASSANDRA 2.0 container has been stopped"
