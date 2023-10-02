#!/bin/bash

Date=$(date +"%Y%m%d")
BackupDir="YOUR_BACKUP_DIR/$Date"
NextcloudDir="YOUR_NEXTCLOUD"

# Create the backup directory
mkdir -p "$BackupDir"

# Enable maintenance mode
sudo -u www-data php "$NextcloudDir/occ" maintenance:mode --on

# Backup Nextcloud files using rsync
sudo rsync -Aavx "$NextcloudDir/" "$BackupDir/nextcloud-backup_$Date/"

# Create a compressed tarball of the Nextcloud backup
tar cfz "$BackupDir/nextcloud-backup_$Date.tgz" -C "$BackupDir" "nextcloud-backup_$Date/"

# Backup the Nextcloud database
sudo mysqldump --single-transaction -h SERVER -u USER -pPASSWORD nextcloud > "$BackupDir/nextclouddb-backup_$Date.bak"

# Disable maintenance mode
sudo -u www-data php "$NextcloudDir/occ" maintenance:mode --off