#!/bin/bash -l
source /home/cell/.rvm/scripts/rvm
HN=$(hostname)
SCRIPT=$(basename $0)
WAIT=2

echo "$(date -uIseconds) $HN $SCRIPT INFO: RUBY 2 container entrypoint starting"
echo "$(date -uIseconds) $HN $SCRIPT INFO: Ruby version: $(ruby -v) gem: $(gem -v)"
# Set variables for using cell_entry.sh
export CELL_EXEC_TYPE="exec" 
export CELL_EXEC_PREFIX=""
export CELL_EXEC_SLEEP=$WAIT 

exec /bin/bash -l