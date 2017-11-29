#!/bin/bash
# Backup domain folder to MEGA.nz script

SERVER="subdomain"
SERVER_NAME="subdomain.domain.com"

MEGA_DIR="/Root/Backups/VDS/production/domains/domain.com"
START_ALL=$(date +%s)
THIS_FILE_PATH="/root/megabackup/domains/${SERVER_NAME}.sh"
LOG_FILE_PATH="/root/megabackup/log/log.txt"
WORKING_DIR="/root/backup_${SERVER_NAME}_dir"
DOMAINS_FOLDER="/srv/domain.com"

# Create local working directory and collect all data
rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}

# Backup domains
DATE=$(date +%F_%T)
START_TAR=$(date +%s)
cd ${DOMAINS_FOLDER}
tar cvf ${WORKING_DIR}/${SERVER_NAME}_${DATE}.tar.xz ${SERVER}
cd - > /dev/null
END_TAR=$(date +%s)
BACKUP_FILE_SIZE=$(stat -c %s ${WORKING_DIR}/${SERVER_NAME}_${DATE}.tar.xz)
BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE}/1024" | bc)

# Create base backup folder
[ -z "$(megals --reload ${MEGA_DIR}/${SERVER_NAME})" ] && megamkdir ${MEGA_DIR}/${SERVER_NAME}

# Create remote folder
START_LOAD=$(date +%s)
curday=$(date +%F)
megamkdir ${MEGA_DIR}/${SERVER_NAME}/${curday} 2> /dev/null

# Upload to MEGA.nz
megacopy --reload -l ${WORKING_DIR} -r ${MEGA_DIR}/${SERVER_NAME}/${curday}
END_LOAD=$(date +%s)

# Clean local environment
rm -rf ${WORKING_DIR}

# Cacl exec time and log it
END_ALL=$(date +%s)
DIFF_ALL=$(( $END_ALL - $START_ALL ))
DIFF_LOAD=$(( $END_LOAD - $START_LOAD ))
DIFF_TAR=$(( $END_TAR - $START_TAR ))
DIFF_ALL=$(printf "%3.0f" $DIFF_ALL)
DIFF_LOAD=$(printf "%3.0f" $DIFF_LOAD)
DIFF_TAR=$(printf "%3.0f" $DIFF_TAR)

if [ $BACKUP_FILE_SIZE -ge 1000 ]
then
BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE}/1024+1" | bc)
BACKUP_FILE_SIZE=$(printf "%4.0f" $BACKUP_FILE_SIZE)
BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE} MB")
else
BACKUP_FILE_SIZE=$(printf "%4.0f" $BACKUP_FILE_SIZE)
BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE} KB")
fi

{
echo "ALL $DIFF_ALL sec | TAR $DIFF_TAR sec | LOAD $DIFF_LOAD sec | ${BACKUP_FILE_SIZE} |" $(date +%F_%T) "| ${THIS_FILE_PATH}"
} >> $LOG_FILE_PATH

exit 0

