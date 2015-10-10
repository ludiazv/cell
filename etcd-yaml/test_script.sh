#!/bin/sh
PREFIX="/etcdyaml_test"

ENDPOINT="http://127.0.0.1:2379"
[ -n "$1" ] && ENDPOINT=$1

./etcd-yaml.rb -p $PREFIX -C $ENDPOINT -f test.yml -k public.gpg import
./etcd-yaml.rb -p $PREFIX -C $ENDPOINT export

