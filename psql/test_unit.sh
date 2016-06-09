#!/bin/sh
fleetctl stop    psql-init@1.service psql-sk@1.service psql@1.service
fleetctl unload  psql-init@1.service psql-sk@1.service psql@1.service
fleetctl destroy psql-init@1.service psql-sk@1.service psql@1.service
fleetctl destroy psql-sk@.service psql@.service psql-init@.service
#fleetctl submit  psql-sk@.service psql@.service
fleetctl submit psql-init@.service psql-sk@.service psql@.service
fleetctl load psql-init@1.service psql@1.service psql-sk@1.service
fleetctl start  psql@1.service psql-sk@1.service
#fleetctl start psql@1.service
#sleep 2
#fleetctl status psql-init@1.service
