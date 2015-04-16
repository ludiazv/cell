#!/bin/sh
PREFIX="/"
etcdctl mkdir $PREFIX/redis
etcdctl mkdir $PREFIX/redis/conf
etcdctl set $PREFIX/redis/conf/tcp-backlog		512
etcdctl set $PREFIX/redis/conf/timeout 			0
etcdctl set $PREFIX/redis/conf/tcp-keepalive 	0
etcdctl set $PREFIX/redis/conf/databases 		5
etcdctl set $PREFIX/redis/conf/loglevel 		notice
etcdctl set $PREFIX/redis/conf/maxclients 		5000
etcdctl set $PREFIX/redis/conf/maxmemory 		150mb
etcdctl set $PREFIX/redis/conf/maxmemory-policy volatile-lru
etcdctl set $PREFIX/redis/conf/lua-time-limit	5000


# bind 192.168.1.100 10.0.0.1
#bind 127.0.0.1 {{getv "/redis/ip-addr"}}
