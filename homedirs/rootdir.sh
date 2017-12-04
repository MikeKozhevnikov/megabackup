#!/bin/bash
# root folder to MEGA.nz backup script

SERVER="root"

MEGA_DIR="/Root/Backups/VDS/production"
START_ALL=$(date +%s)
THIS_FILE_PATH="/root/megabackup/homedirs/${SERVER}dir.sh"
LOG_FILE_PATH="/root/megabackup/log/log.txt"
WORKING_DIR="/var/tmp/backup_tmp_${SERVER}dir_dir"

# Create local working directory and collect all data
rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}

# Backup /root folder
START_TAR=$(date +%s)
cd /
DATE=$(date +%F_%T)
tar --exclude='${SERVER}dir_${DATE}.tar.gx' -cvf ${WORKING_DIR}/${SERVER}dir_${DATE}.tar.gx ${SERVER}
cd - > /dev/null
END_TAR=$(date +%s)
BACKUP_FILE_SIZE=$(stat -c %s ${WORKING_DIR}/${SERVER}dir_${DATE}.tar.gx)
BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE}/1024" | bc)

# Create base backup folder
[ -z "$(megals --reload ${MEGA_DIR}/homedirs/${SERVER})" ] && megamkdir ${MEGA_DIR}/homedirs/${SERVER}

# Create remote folder
START_LOAD=$(date +%s)
curday=$(date +%F)
megamkdir ${MEGA_DIR}/homedirs/${SERVER}/${curday} 2> /dev/null

# Load to MEGA.nz
megacopy --reload -l ${WORKING_DIR} -r ${MEGA_DIR}/homedirs/${SERVER}/${curday}
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
