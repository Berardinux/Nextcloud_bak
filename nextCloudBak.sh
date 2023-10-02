#!/bin/bash

:"
Ensure that you've replaced {
/PATH/TO/YOUR/BACKUP/DIRECTORY,
/PATH/TO/YOUR/NEXTCLOUD, 
YOUR_DB_USER, 
YOUR_DB_PASSWORD }
with your actual directory and database information.

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
"

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

Date=$(date +"%Y%m%d")
BackupDir="/PATH/TO/YOUR/BACKUP/DIRECTORY/$Date"
NextcloudDir="/PATH/TO/YOUR/NEXTCLOUD"
User="YOUR_DB_USER"
Passwd="YOUR_DB_PASSWORD"
Database="localhost"
Log="$BackupDir/ncScript.log"
max_backups=10

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
backup_count=$(find "$BackupDir" -maxdepth 1 -type d -name "20*" | wc -l)

# If there are more than the maximum allowed backups, remove the oldest ones
if [ "$backup_count" -gt "$max_backups" ]; then
    # Use find to list backup directories, sort them by modification time, and delete the oldest ones
    find "$BackupDir" -maxdepth 1 -type d -name "20*" -printf "%T@ %p\n" | sort -n | head -n "$((backup_count - max_backups))" | cut -d ' ' -f 2- | xargs rm -rf
    echo "Removed the oldest backup directories to maintain a maximum of $max_backups backups." >> "$Log"
fi