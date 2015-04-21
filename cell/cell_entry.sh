#!/bin/sh
# Entry point for cell, simply call confcell.sh to be sure that all files are syncronized
SCRIPT=$(basename $0)
HN=$(hostname)
WAIT=3
[ -z "$CELL_CONFD_INTERVAL" ] && CELL_CONFD_INTERVAL=60

echo "$(date -uIseconds) $HN $SCRIPT INFO: Booting cell"
if [ -n "$CONFCELL_URL" ] && [ -n "$CONFCELL_MANIFEST_ID" ]; then
	echo "$(date -uIseconds) $HN $SCRIPT INFO: Running confcell.sh with URL=${CONFCELL_URL} & MAN_ID=${CONFCELL_MANIFEST_ID}"
	CDIR=$(pwd)
	cd /opt/confcell
	./confcell.sh
	cd $CDIR
else
	echo "$(date -uIseconds) $HN $SCRIPT INFO: Skiping confcell.sh as no URL and MAN_ID provided"
fi
# Run confd in background within the container
echo "Debug pars: CELL_ETCD_PREFIX=$CELL_ETCD_PREFIX,CELL_CONFD_INTERVAL=$CELL_CONFD_INTERVAL,CELL_ETCD_NODE=$CELL_ETCD_NODE"
[ -z "$CELL_ETCD_PREFIX" ] && CELL_ETCD_PREFIX="/"
[ -z "$CELL_ETCD_NODE" ] && CELL_ETCD_NODE="http://$HOST_IP:4001"

ETCD_NODE=$CELL_ETCD_NODE

echo "$(date -uIseconds) $HN $SCRIPT INFO: Starting confd for node $ETCD_NODE with prefix $CELL_ETCD_PREFIX ..."
echo "$(date -uIseconds) $HN $SCRIPT INFO: Killing any running confd ..."
killall confd > /dev/null 2>/dev/null
sleep $WAIT
nice confd -backend etcd -node $ETCD_NODE -interval $CELL_CONFD_INTERVAL -prefix $CELL_ETCD_PREFIX &
sleep $WAIT

# Execute command $CELL_EXEC_PREFIX + $CELL_EXEC_TYPE + $CMD + $CELL_EXEC_BACKGROUND
#   $CELL_EXEC_PREFIX can be set to make sudo / su / gosu to run process as other user.
#	$CELL_EXEC_TYPE can be "shell" or "exec" to create a child process or use current by default
#   $CMD is commmand to execute captured from command line parameters
#   $CELL_EXEC_BACKGROUND can be "" or "&" if "sell" exec type is selected to launch cell in background mode
#   $CELL_EXE_SLEEP can be set to wait some time before execution by default it wait 3 seconds

CMD="$@"
[ -z "$CMD" ] && CMD="/bin/sh"
[ -z "$CELL_EXEC_TYPE" ] && CELL_EXEC_TYPE="exec"
[ -z "$CELL_EXEC_SLEEP" ] && CELL_EXEC_SLEEP=3
echo "Debug: EXCEC=$CELL_EXEC_TYPE CMD=$CMD , PREFIX=$CELL_EXEC_PREFIX , BG=$CELL_EXEC_BACKGROUND"
sleep $CELL_EXEC_SLEEP

if [ "$CELL_EXEC_TYPE" = "exec" ]; then
	CMDS="exec $CELL_EXEC_PREFIX $CMD"
else
	CMDS="$CELL_EXEC_PREFIX $CMD $CELL_EXEC_BACKGROUND"
fi

echo "$(date -uIseconds) $HN $SCRIPT INFO: Running command [ ${CMDS} ] ..."
eval $CMDS

