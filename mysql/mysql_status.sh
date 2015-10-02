#!/bin/bash
pid=$(pidof mysqld)
if [ $? -eq 0 ] ; then
	echo "$(mysql --version) / running with pid:$pid."
else
    echo "Mysql is not running"
fi