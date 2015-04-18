#!/bin/sh
gosu postgres /opt/psqlbin/pg_ctl status > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
	gosu postgres /opt/psqlbin/pg_ctl stop -s -m fast
	gosu postgres /opt/psqlbin/pg_ctl status
fi
exit 0