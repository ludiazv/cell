#!/bin/sh
SUP="gosu cassandra"
CQL="$SUP /opt/cassandra/bin/cqlsh"

[ -z "$CELL_DB" ] && CELL_DB="cell"
[ -z "$CELL_USER" ] && CELL_USER="cell"
[ -z "$CELL_PWD" ] && CELL_PWD="cell"

echo "CANSSANDRA INITDB on /opt/cassandra-data ...."
echo "---------------------------------------------"
echo "$HOST_IP $HOST_NAME" >> /etc/hosts
chown -R cassandra:cassandra /opt/cassandra-data && chown -R cassandra:cassandra /opt/cassandra 
chown -R cassandra:cassandra /opt/dsc-cassandra-2.0.14 && chown -R cassandra:cassandra /opt/cassandra-log
# Run confd onetime to configure node
[ -z "$CELL_ETCD_PREFIX" ] && CELL_ETCD_PREFIX="/"
[ -z "$CELL_ETCD_NODE" ] && CELL_ETCD_NODE="http://$HOST_IP:4001"

ETCD_NODE=$CELL_ETCD_NODE
confd -onetime -backend etcd -node $ETCD_NODE -prefix $CELL_ETCD_PREFIX
sleep 2
# start server
$SUP /opt/cassandra/bin/cassandra 
sleep 20
#echo "ALTER KEYSPACE system_auth WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2 };" > /opt/tmp.cql
#echo "ALTER USER cassandra WITH PASSWORD '$(openssl rand -base64 32)' NOSUPERUSER;" >> /opt/tmp.cql
echo "CREATE USER IF NOT EXISTS $CELL_USER WITH PASSWORD '$CELL_PWD' SUPERUSER;" >> /opt/tmp.cql
echo "LIST USERS;" >> /opt/tmp.cql
echo "CREATE KEYSPACE IF NOT EXISTS cell WITH REPLICATION={ 'class' : 'SimpleStrategy', 'replication_factor' : 2};" >> /opt/tmp.cql
echo "DESCRIBE CLUSTER;" >> /opt/tmp.cql
echo "DESCRIBE KEYSPACES;" >> /opt/tmp.cql
chown -R cassandra:cassandra /opt/tmp.cql
$CQL -u cassandra -p cassandra -f /opt/tmp.cql $HOST_IP
rm -f /opt/tmp.cql
#/bin/bash
killall java
sleep 10
echo "Data container initializaed at $(date -uIseconds) DB=$CELL_DB USER=$CELL_USER" > /opt/cassandra-data/CELL_CASS_INIT.txt
