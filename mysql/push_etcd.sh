#!/bin/bash
PREFIX="/"
DIR="${PREFIX}mysql"
CONF="$DIR/conf"
etcdctl mkdir $DIR
etcdctl mkdir $CONF
CNF=""
read -r -d '' CNF <<-EOF
query_cache_type = 1
query_cache_limit = 256K
query_cache_min_res_unit = 2k
query_cache_size = 35M
EOF
echo $CNF
etcdctl set $CONF/mysqld 		"$CNF"
