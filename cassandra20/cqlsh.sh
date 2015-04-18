#!/bin/sh
docker exec -t -i cas gosu cassandra /opt/casbin/cqlsh -u cell -p cell $(hostname)