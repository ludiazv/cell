#!/bin/sh
docker exec -t -i $1 gosu cassandra /opt/casbin/cqlsh -u $2 -p $3 $(hostname)
