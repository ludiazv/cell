#!/bin/sh
source /etc/environment
PREFIX="/"
docker run -i --rm -t --name memcached \
	   -e MC_SIZE=20 -e MC_CONN=256 \
	   -p ${COREOS_PRIVATE_IPV4}:11211:11211 
	   atlo/memcached:latest