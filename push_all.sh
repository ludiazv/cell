#!/bin/sh
docker login
docker push atlo/cell
docker push atlo/redis28
docker push atlo/psql94
docker push atlo/ruby2
docker push atlo/rails42
#docker push atlo/memcached
docker push atlo/jre7
docker push atlo/cassandra20
docker push atlo/elasticsearch15