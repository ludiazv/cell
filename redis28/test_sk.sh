#!/bin/sh
fleetctl destroy redis-sk@.service
fleetctl destroy redis-sk@1.service
fleetctl submit redis-sk@.service
fleetctl start redis-sk@1.service
fleetctl status redis-sk@1.service

