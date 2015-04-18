#!/bin/sh
PREFIX="/"
etcdctl mkdir $PREFIX/nginx
etcdctl mkdir $PREFIX/nginx/conf
etcdctl set $PREFIX/nginx/conf/tcp-backlog		512



