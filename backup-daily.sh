#!/bin/bash

WORKDIR=/backup/db/sql/daily
LOG=/backup/db/log/backup-daily.log


if [ -a $WORKDIR/backup-daily.lock ]; then
	mail -s "$(date +%Y-%m-%d\ %H:%M:%S) MySQL Daily Backup FAILED, please check the mysqldump proccess" aditya.hilman@gmail.com <<< $( ls -l $WORKDIR | grep lock )
else
	touch $WORKDIR/backup-daily.lock
	for DbDaily in $( cat /home/ubuntu/backupdb/daily-table.csv ); do
		mysqldump -ubsbackup -pdbuser -h dbhost --no-autocommit --extended-insert=false --single-transaction borobudur "$DbDaily" > $WORKDIR/$DbDaily-$(date +%Y%m%d).sql
		bzip2 $WORKDIR/$DbDaily-$(date +%Y%m%d).sql
		s3cmd put $WORKDIR/$DbDaily-$(date +%Y%m%d).sql.bz2 s3://backup-bucket-db-backup/2016/daily/$DbDaily-$(date +%Y%m%d).sql.bz2
		rm -f $WORKDIR/$DbDaily-$(date +%Y%m%d).sql
	done
	ls -ltrh $WORKDIR | grep "$(date +%Y%m%d)" > $WORKDIR/daily-list
	cat $WORKDIR/daily-list	| mail -s "$(date +%Y-%m-%d\ %H:%M:%S) MySQL Daily Backup SUCCESS" aditya.hilman@gmail.com
	rm -f $WORKDIR/backup-daily.lock
fi
