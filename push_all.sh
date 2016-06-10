#!/bin/sh
docker login
# Base
docker push atlo/cell
docker push atlo/cell-alpine
docker push atlo/registry:1.0
docker push atlo/registry

# Langs and frameworks
#docker push atlo/node
docker push atlo/golang14
docker push atlo/ruby2
docker push atlo/ruby2-alpine
docker push atlo/jruby9k
docker push atlo/rails42
docker push atlo/jre7

# DBs + Caches
docker push atlo/redis28
docker push atlo/redis
docker push atlo/memcached
docker push atlo/cassandra20
#docker push atlo/elasticsearch15
docker push atlo/psql
docker push atlo/mysql

# Services
#docker push atlo/nginx

#Extras
docker push atlo/etcd-yaml
docker push atlo/sass-compiler

# Applications
#docker push atlo/wordpress
