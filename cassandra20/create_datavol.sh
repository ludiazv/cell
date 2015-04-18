#!/bin/sh
DPS=$(docker ps -a | grep cas-data-vol)
if [ -z "$DPS" ]; then
	echo "Data container do not exists ... creating it as cas-data-vol"
	docker create --name="cas-data-vol" -v /opt/cassandra-data atlo/cassandra20
else
	echo "Container exists with the following volumes..."
	docker inspect cas-data-vol | grep /opt/cassandra-data
fi