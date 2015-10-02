#!/bin/sh

#sudo userdel -r mysql
#sudo groupdel mysql

#sudo rm -rf /opt/mysql-data


fleetctl stop    mysql-init@1.service mysql@1.service mysql-sk@1.service
fleetctl unload  mysql-init@1.service mysql@1.service mysql-sk@1.service
fleetctl destroy mysql-init@.service mysql-init@1.service \
				 mysql@1.service mysql@.service \
				 mysql-sk@1.service mysql-sk@.service
read
fleetctl submit mysql-init@.service mysql@.service mysql-sk@.service
fleetctl load mysql-init@1.service mysql@1.service mysql-sk@1.service
fleetctl start mysql-init@1.service mysql@1.service mysql-sk@1.service

fleetctl list-unit-files
fleetctl list-units


sleep 6
fleetctl status mysql-init@1
fleetctl status mysql@1
fleetctl status mysql-sk@1
