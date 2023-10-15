#!/bin/bash

# Ensure that you have replaced {
# /PATH/TO/YOUR/BACKUP/DIRECTORY,
# /PATH/TO/YOUR/PLEX,
# }

# Print ASCII art
cat << "EOF"
        .:okOXNWWMMWWNXOko:.
      ONMMMMMMMMMMMMMMMMMMMMWO
      0MMMMMMMMMMMMMMMMMMMMMM0
      ;MMMMMMMMMMMMMMMMMMMMMM;
       MMMMMMMMMMMMMMMMMMMMMM
       NMMMMMMMMMMMMMMMMMMMMM
       lMMMMMMMMMMMMMMMMMMMMx
       .MMMMMMMMMMMMMMMMMMMM.
        MMMMMMMMMMMMMMMMMMMM
        xMMMMMMMMMMMMMMMMMMO
        'MMMMMMMMMMMMMMMMMM;
  .;ldO0NMMMMMMMMMMMMMMMMMMN0Odl;.
cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo
    dMMMMMMMMMMMMMMMMMMMMMMMMMMx

       d                    o
       ;                    ,
       0                    k
      lM                    Xl
     .MM                    XM.
     ;MM,                  ,MM:
      ;MMKo,            ,o0MM:
        xMMMMKd;.  .;dKMMMMO
          cMMMMMMMMMMMMMMl
             .MMMMMMMM,
                 ..
EOF

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi


Date=$(date +"%Y%m%d")                             # < Variable that shows the date
BackupDir="/PATH/TO/YOUR/BACKUP/DIRECTORY/$Date"   #< Where the new Nextcloud backup is stored. 
NextcloudBak="/PATH/TO/ALL/YOUR/NEXTCLOUD/BACKUPS" #< Where the Nextcloud backup directorys are.
MaxBak="2"                                         #< Change this to change the total amount of backups you will store before deletion.
NextcloudDir="/PATH/TO/YOUR/NEXTCLOUD"             #< Where running Nextcloud is. 
User="YOUR_DB_USER"                                #< DB User
Passwd="YOUR_DB_PASSWORD"                          #< DB Passwd
Database="localhost"                               #< DB Location
Log="$BackupDir/ncScript.log"                      #< Backup Logs

# Create the backup directory
if [ -d "$BackupDir" ] || [ -d "$Log" ]; then
    echo "Backup directory $BackupDir or log file $Log already exists." >> "$Log"
else
    mkdir -p "$BackupDir"
    touch "$Log"
fi

# Enable maintenance mode
sudo -u www-data php "$NextcloudDir/occ" maintenance:mode --on

# Backup Nextcloud files using rsync
if rsync -Aavx "$NextcloudDir/" "$BackupDir/nextcloud-backup_$Date/"; then
    echo "Nextcloud files backup completed successfully." >> "$Log"
else
    echo "Nextcloud files backup failed." >> "$Log"
fi

# Create a compressed tarball of the Nextcloud backup
tar cfz "$BackupDir/nextcloud-backup_$Date.tgz" -C "$BackupDir" "nextcloud-backup_$Date/"

# Backup the Nextcloud database
if mysqldump --single-transaction -h $Database -u "$User" -p"$Passwd" nextcloud > "$BackupDir/nextclouddb-backup_$Date.bak"; then
    echo "Nextcloud database backup completed successfully." >> "$Log"
else
    echo "Nextcloud database backup failed." >> "$Log"
fi

# Disable maintenance mode
sudo -u www-data php "$NextcloudDir/occ" maintenance:mode --off

# Count the number of existing backup directories
BakCount=$(find "$NextcloudBak" -maxdepth 1 -type d -name "20*" | wc -l)

# If there are more than the maximum allowed backups, remove the oldest ones
if [ "$BakCount" -gt "$MaxBak" ]; then
    # Use find to list backup directories, sort them by modification time, and delete the oldest ones
    find $NextcloudBak -maxdepth 1 -type d -name "20*" -printf "%T@ %p\n" | sort -n | head -n "$((BakCount - MaxBak))" | cut -d ' ' -f 2- | xargs rm -rf
    echo "Removed the oldest backup directories to maintain a maximum of $max_backups backups." >> "$Log"
fi
