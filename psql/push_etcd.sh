#!/bin/sh
PREFIX="/"
DIR="${PREFIX}psql"
CONF="$DIR/conf"
etcdctl mkdir $DIR
etcdctl mkdir $CONF
etcdctl set $CONF/max_connections 		'250'
etcdctl set $CONF/shared_buffers		'100MB'
etcdctl set $CONF/work_mem				'16MB'
etcdctl set $CONF/maintenance_work_mem  '32MB'


# HB host+ip+md5
etcdctl mkdir $CONF/hba				
etcdctl set   $CONF/hba/rule-1 '{"db":"cell","user":"cell","address":"172.17.8.0/24"}'
etcdctl set   $CONF/hba/rule-2 '{"db":"postgres","user":"cell","address":"192.168.1.33/32"}'
