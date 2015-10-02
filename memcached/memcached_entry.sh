#!/bin/bash
echo "Starting memcached container..."
# Set default values for variables
[ -z "$MC_USER"  ] && MC_USER="cell"
[ -z "$MC_SIZE"  ]  && MC_SIZE=64
[ -z "$MC_CONN"  ]  && MC_CONN=512
[ -z "$MC_PROTO" ] && MC_PROTO="auto"
#/bin/bash
exec /usr/bin/memcached -p 11211 -u ${MC_USER} -m ${MC_SIZE} -c ${MC_CONN} -B ${MC_PROTO}