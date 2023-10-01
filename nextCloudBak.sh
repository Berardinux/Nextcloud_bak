#!/bin/bash

sudo -u www-data php occ maintenance:mode --on

sudo rsync -Aavx nextcloud/ /LOCATION/nextcloud-backup_`date +"%Y%m%d"`/

tar cfz /LOCATION/nextcloud-backup_DATE.tgz /LOCATION/nextcloud-backup_DATE/

sudo mysqldump --single-transaction -h SERVER -u USER -p nextcloud > nextclouddb-backup_`date +%Y%m%d"`.bak

sudo -u www-data php occ maintenance:mode --off
