#!/bin/sh
fleetctl unload  psql-sk@1.service psql@1.service
fleetctl destroy psql-sk@.service psql@.service
fleetctl destroy psql-sk@1.service psql@1.service
fleetctl submit  psql-sk@.service psql@.service
#fleetctl load   psql@1.service psql-sk@1.service
fleetctl start  psql@1.service psql-sk@1.service
fleetctl status psql@1.service
