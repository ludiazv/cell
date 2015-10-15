#!/bin/bash
# This image manipultes /proc and it needs to run in privileged mode
#set -e
# Set SO maxconnectios to 4K
#sysctl -w net.core.somaxconn=4128 > /dev/null
# Avoids fails on save to disk
#sysctl -w vm.overcommit_memory=1 > /dev/null
#sysctl -p

# Main control variables
WAIT=5
SCRIPT=$(basename $0)
HN=$(hostname)

#trap "DO_LOOP=false && killall -q redis-server && killall -q confd" HUP INT QUIT KILL TERM EXIT

# Set variables for using cell_entry.sh
export CELL_EXEC_TYPE="exec" # Lauch redis server as shell
export CELL_EXEC_BACKGROUND="" # in background NO
export CELL_EXEC_PREFIX="gosu nginx" # as nginx
export CELL_EXEC_SLEEP=$WAIT  	# wait 5 seconds to start it

echo "$HN $SCRIPT INFO: Nginx $NGINX_VERSION contaniner starts"
# Change some parameters in php
#sed -i "s/^\(bind-address.*=\).*/\1${CELL_LOCAL_IP}/" 

if [ -z "$CELL_NO_PHP" ] ; then

	echo "$HN $SCRIPT INFO: Starting PHP-PFM...."
	php5-fpm  -t --fpm-config /etc/php5/fpm/php-fpm.conf
	if [ $? -eq 0 ] ; then
		php5-fpm  --fpm-config /etc/php5/fpm/php-fpm.conf
		[ $? -ne 0 ] && echo "$HN $SCRIPT ERROR: Could not be launched." && exit 1
	
	else
		echo "$HN $SCRIPT ERROR: Configuration of fpm is not valid."
    	exit 1
	fi	
	echo "$HN $SCRIPT INFO: Started with pid $(cat /var/run/php5-fpm.pid)"
else
	echo "$HN $SCRIPT INFO: CELL_NO_PHP env set. PHP-PFM will not run."
fi

confd -onetime -backend etcd -node http://172.17.8.101:2379 -prefix /nginx_test/
cat /etc/nginx/nginx.conf

exit 0
#/opt/cell_entry.sh 
#while $DO_LOOP; do
#	pidof redis-server > dev/null
#	if [[ $? -eq 0 ]]; then
		# server is runing if restart
#		if [[ -f "/opt/redis_restart.txt" ]]; then
#			echo "$(date -uIseconds) $HN $SCRIPT INFO: Redis running with pid $(pidof redis-server), killing it"
#			killall -q redis-server
#			sleep $WAIT
#		else
#			read -t $WAITLG  # Wait 20 seconds but be able to be interupted buy trap.
#		fi
#	else
#		# inititate server
#		/opt/cell_entry.sh \'exec redis-server /etc/redis/redis.conf\'
#		sleep $WAIT
#		echo "$(date -uIseconds) $HN $SCRIPT INFO: Redis started with pid $(pidof redis-server)"
#		rm -f /opt/redis_restart.txt
#	fi
#done
/bin/bash
echo "$(date -uIseconds) $HN $SCRIPT INFO: Nginx 1.6 container has been stopped"