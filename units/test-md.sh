#!/bin/sh
fleetctl stop cell-metadata.service
fleetctl destroy cell-metadata.service
fleetctl submit cell-metadata.service
fleetctl start cell-metadata.service
fleetctl status cell-metadata.service