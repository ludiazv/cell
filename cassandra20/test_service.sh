#!/bin/bash
fleetctl unload cassandra20-seed@.service cassandra20-seed@1.service cassandra20-seed-sk@1.service \
				cassandra20-node@.service cassandra20-node@1.service cassandra20-node-sk@1.service
sleep 5
fleetctl list-units
fleetctl destroy cassandra20-seed@.service cassandra20-seed@1.service \
				 cassandra20-seed-sk@.service cassandra20-seed-sk@1.service \
				 cassandra20-node@.service cassandra20-node@1.service \
				 cassandra20-node-sk@.service cassandra20-node-sk@1.service	
fleetctl list-unit-files
read
fleetctl submit cassandra20-seed@.service cassandra20-seed-sk@.service \
				cassandra20-node@.service cassandra20-node-sk@.service 
fleetctl list-unit-files
read
fleetctl load cassandra20-seed@1.service cassandra20-seed-sk@1.service \
			  cassandra20-node@1.service cassandra20-node-sk@1.service

fleetctl start cassandra20-seed@1.service cassandra20-seed-sk@1.service \
			   cassandra20-node@1.service cassandra20-node-sk@1.service
sleep 5
fleetctl list-units