#!/bin/bash
# This image manipultes /proc and it needs to run in privileged mode
#set -e
# Set SO maxconnectios to 4K
sysctl -w net.core.somaxconn=4128 > /dev/null
# Avoids fails on save to disk
sysctl -w vm.overcommit_memory=1 > /dev/null
sysctl -p
# Disable THP
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# Set trap to kill all processes when docker stop
DO_LOOP=true
WAIT=8
WAITLG=60
SCRIPT=$(basename $0)
HN=$(hostname)

trap "DO_LOOP=false && killall -q redis-server && killall -q confd" HUP INT QUIT KILL TERM EXIT

# Set variables for using cell_entry.sh
export CELL_EXEC_TYPE="shell" # Lauch redis server as shell
export CELL_EXEC_BACKGROUND="&" # in background
export CELL_EXEC_PREFIX="gosu redis /bin/sh -c" # as redis
export CELL_EXEC_SLEEP=$WAIT  # wait 5 seconds to start it

echo "$(date -uIseconds) $HN $SCRIPT INFO: Redis 2.8 container entrypoint starting"
while $DO_LOOP; do
	pidof redis-server > dev/null
	if [[ $? -eq 0 ]]; then
		# server is runing if restart
		if [[ -f "/opt/redis_restart.txt" ]]; then
			echo "$(date -uIseconds) $HN $SCRIPT INFO: Redis running with pid $(pidof redis-server), killing it"
			killall -q redis-server
			sleep $WAIT
		else
			read -t $WAITLG  # Wait 20 seconds but be able to be interupted buy trap.
		fi
	else
		# inititate server
		/opt/cell_entry.sh \'exec redis-server /etc/redis/redis.conf\'
		sleep $WAIT
		echo "$(date -uIseconds) $HN $SCRIPT INFO: Redis started with pid $(pidof redis-server)"
		rm -f /opt/redis_restart.txt
	fi
done

echo "$(date -uIseconds) $HN $SCRIPT INFO: Redis 2.8 container has been stopped"