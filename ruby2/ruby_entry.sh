#!/bin/bash -l
source /home/cell/.rvm/scripts/rvm
HN=$(hostname)
SCRIPT=$(basename $0)

if [ -n "$CELL_NO_BANNER" ] ; then
	echo "$HN $SCRIPT INFO: RUBY 2 container entrypoint starting"
	echo "$HN $SCRIPT INFO: Ruby version: $(ruby -v) gem: $(gem -v)"
	echo "Running $@..."
fi

if [[ -z "$@" ]] ; then
	irb
else
	eval "$@"
fi

#exec /bin/bash -l -c '$@'