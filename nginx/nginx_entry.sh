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
export CELL_EXEC_PREFIX="" # as nginx
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
	echo "$HN $SCRIPT INFO: PHP-FPM started with pid $(cat /var/run/php5-fpm.pid)"
else
	echo "$HN $SCRIPT INFO: CELL_NO_PHP env set. PHP-PFM will not run."
fi

#confd -onetime -backend etcd -node http://172.17.8.101:2379 -prefix /nginx_test/
#cat /etc/nginx/nginx.conf
[ -f "/opt/nginx.pid" ] && rm -f /opt/nginx.pid # Remove pid if exists
/opt/cell_entry.sh "nginx -g 'daemon off;'"

# Ensuring kill all
killall php5-fpm
killall nginx

echo "$(date -uIseconds) $HN $SCRIPT INFO: Nginx 1.6 container has been stopped"