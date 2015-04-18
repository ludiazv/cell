#!/bin/sh
DPS=$(docker ps -a | grep redis-data-vol)
if [ -z "$DPS" ]; then
	echo "Data container do not exists ... creating it"
	docker create --name="redis-data-vol" -v /opt/redis_data atlo/redis28
else
	echo "Container exists with the following volumes..."
	docker inspect redis-data-vol | grep /opt/redis_data
fi
