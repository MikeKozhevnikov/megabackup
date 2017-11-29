#!/bin/bash
# MySql bases to MEGA.nz backup script

SERVER="mysql"

MEGA_DIR="/Root/Backups/VDS/production/mysql/root"
START_ALL=$(date +%s)
THIS_FILE_PATH="/root/megabackup/mysql/mysql_root.sh"
LOG_FILE_PATH="/root/megabackup/log/log.txt"
WORKING_DIR="/root/backup_tmp_${SERVER}_dir"
BACKUP_MYSQL="true"
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# Create local working directory and collect all data
rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}
cd ${WORKING_DIR}

# Backup MySQL
START_TAR=$(date +%s)
DATE=$(date +%F_%T)
BACKUP_FILE_SIZE=0
if [ "${BACKUP_MYSQL}" = "true" ]
then
 for db in $(mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e 'show databases;' | grep -Ev "^(Database|mysql|information_schema|performance_schema|phpmyadmin)$")
 do
 echo "processing ${db}"
 mysqldump --opt -u${MYSQL_USER} -p${MYSQL_PASSWORD} "${db}" | gzip > ${WORKING_DIR}/${db}_${DATE}.sql.gz
 TEMP=$(stat -c %s ${WORKING_DIR}/${db}_${DATE}.sql.gz)
 BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE}+${TEMP}" | bc)
done
 echo "all db now"
 mysqldump --opt -u${MYSQL_USER} -p${MYSQL_PASSWORD} --events --ignore-table=mysql.event --all-databases | gzip > ${WORKING_DIR}/ALL_DATABASES_${DATE}.sql.gz
 TEMP=$(stat -c %s ${WORKING_DIR}/ALL_DATABASES_${DATE}.sql.gz)
 BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE}+${TEMP}" | bc)
fi
END_TAR=$(date +%s)

# Create base backup folder
[ -z "$(megals --reload ${MEGA_DIR})" ] && megamkdir ${MEGA_DIR}

# Create remote folder
START_LOAD=$(date +%s)
curday=$(date +%F)
megamkdir ${MEGA_DIR}/${curday} 2> /dev/null

# Load to MEGA.nz
megacopy --reload -l ${WORKING_DIR} -r ${MEGA_DIR}/${curday}
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


BACKUP_FILE_SIZE=$(echo "${BACKUP_FILE_SIZE}/1024" | bc)
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
