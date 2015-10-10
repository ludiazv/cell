#!/bin/bash
PREFIX="/"
DIR="${PREFIX}mysql"
CONF="$DIR/conf"
CRD="$DIR/credentials"
etcdctl mkdir $DIR
etcdctl mkdir $CONF

# Configuring users and passwords.
etcdctl mkdir $CRD
etcdctl set $CRD/db 'mydb'
etcdctl set $CRD/db-user 'mydbuser'
echo "cell" > /tmp/userpwd.txt
echo "cell_root" > /tmp/rootpwd.txt
echo "bkup" > /tmp/bkuppwd.txt
crypt set -endpoint="http://localhost:2379" -keyring="/opt/keyring/.public.gpg" $CRD/db-user-pwd /tmp/userpwd.txt
crypt set -endpoint="http://localhost:2379" -keyring="/opt/keyring/.public.gpg" $CRD/db-root-pwd /tmp/rootpwd.txt
crypt set -endpoint="http://localhost:2379" -keyring="/opt/keyring/.public.gpg" $CRD/db-bkup-pwd /tmp/bkuppwd.txt
shred -zn 3 /tmp/userpwd.txt /tmp/rootpwd.txt /tmp/bkuppwd.txt

CNF=""
read -r -d '' CNF <<-EOF
query_cache_type = 1
query_cache_limit = 256K
query_cache_min_res_unit = 2k
query_cache_size = 30M
EOF
echo $CNF
etcdctl set $CONF/mysqld 		"$CNF"

