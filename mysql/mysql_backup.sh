#!/bin/bash
SCRIPT=$(basename $0)
MYSQL_DATA="/opt/mysql-data"
BKP_OPTS="--force -opt"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/opt/mysq-backup"
MYSQL_USER="bckup"
MYSQL_PASSWORD="#pkt3wsd2$e19"

echo "$SCRIPT MYSQL Simple Back up started..."
# check if mysq has ben initlizized
if [ ! -f $MYSQL_DATA/mysql_cell_init.txt ]; then
	echo "$SCRIPT ERROR: MYSQL not initlizized please run the container with --entrypoint=/opt/mysql_init.sh"
	exit 1
fi

[ -z "$1" ] && COMPRESS="gzip -9"

databases=`mysql --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
echo "Backing up $databases...."
for db in $databases; do
  mysqldump $BKP_OPTS --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | $COMPRESS > "$db.$TIMESTAMP.gz"
done
echo "done!"