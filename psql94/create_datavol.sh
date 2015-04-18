#!/bin/sh
DPS=$(docker ps -a | grep psql94-data-vol)
if [ -z "$DPS" ]; then
	echo "Data container do not exists ... creating it as psql94-data-vol"
	docker create --name="psql94-data-vol" -v /opt/psql-data atlo/psql94
else
	echo "Container exists with the following volumes..."
	docker inspect psql94-data-vol | grep /opt/psql-data
fi
DPS=""
DPS=$(docker ps -a | grep psql94-backup-vol)
if [ -z "$DPS" ]; then
	echo "Data backup container do not exists ... creating it as psql94-backup-vol"
	docker create --name="psql94-backup-vol" -v /opt/psql-backup atlo/psql94
else
	echo "Data backup container exists with the following volumes..."
	docker inspect psql94-backup-vol | grep /opt/psql-backup
fi
