#!/bin/sh
curl -O http://download.panamax.io/installer/panamax-latest.tar.gz && mkdir -p /var/panamax && tar -C /var/panamax -zxvf panamax-latest.tar.gz
cd /var/panamax
