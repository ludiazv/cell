#!/bin/sh
PREFIX="/"
CONF="$PREFIX/cassandra/conf"
etcdctl mkdir $PREFIX/cassandra/conf
etcdctl set ${PREFIX}cassandra/172.17.8.101 'seed'
etcdctl set ${PREFIX}cassandra/172.17.8.102 'no-seed'
etcdctl set $CONF/seeds		'172.17.8.102'

