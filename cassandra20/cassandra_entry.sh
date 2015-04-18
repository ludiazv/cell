#!/bin/sh
HN=$(hostname)
SCRIPT=$(basename $0)
WAIT=10

echo "$(date -uIseconds) $HN $SCRIPT INFO: CASSANDRA 2.0 container entrypoint starting"
# check if pql has ben initlizized
if [ ! -f /opt/cassandra-data/CELL_CASS_INIT.txt ]; then
	echo "$(date -uIseconds) $HN $SCRIPT ERROR: CASSANDRA data directory is not initilized, run container with --entrypoint='/opt/cassandra_init.sh' to initialice the DB"
	exit 1
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

#/opt/cell_entry.sh /bin/bash
exec /bin/sh /opt/cell_entry.sh /opt/cassandra/bin/cassandra -f -p /opt/cassandra_pid.pid
#echo "$(date -uIseconds) $HN $SCRIPT INFO: CASSANDRA 2.0 container has been stopped"
