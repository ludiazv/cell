#!/bin/sh
HN=$(hostname)
SCRIPT=$(basename $0)
WAIT=10
DO_LOOP=true

echo "$(date -uIseconds) $HN $SCRIPT INFO: CASSANDRA 2.0 container entrypoint starting"
# check if pql has ben initlizized
if [ ! -f /opt/cassandra-data/CELL_CASS_INIT.txt ]; then
	echo "InitDB cell casandra DB"
	#/opt/cassandra_init.sh
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

rm -f /opt/cassandra_pid.pid # Remove pid file if exisits

while $DO_LOOP; do
	if [ -e "/opt/cassandra/casscell.pid" ] ; then
		# server is possible running
		ps $(cat /opt/cassandra/casscell.pid) > /dev/null
		if [ $? -eq 0 ] ; then
			if [ -e "/opt/cassandra_restart.txt" ] ; then
				echo "Stoping cassandra..."
				rm -f /opt/cassandra_restart.txt
				kill $(cat /opt/cassandra/casscell.pid)
				killall -q java
			else
				sleep 90
			fi
		else
			#remove dirty pid file
			echo "WARN: Remove dirty PID"
			rm -f /opt/cassandra/casscell.pid
		fi
	else
		# server is not running -> do start it
		echo "Cassandra process not found... starting cassandra...."
		killall -q java
		/opt/cell_entry.sh /opt/cassandra/bin/cassandra -p /opt/cassandra/casscell.pid
		sleep 90
		rm -f /opt/cassandra_restart.txt # Clean restart on init
		echo "Cassandra process started with PID=$(cat /opt/cassandra/casscell.pid)"
	fi
	sleep 5 # Give some time
done
echo "$(date -uIseconds) $HN $SCRIPT INFO: CASSANDRA 2.0 container has been stopped"
