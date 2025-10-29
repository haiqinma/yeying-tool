#!/usr/bin/env bash
# this script is used to bakup wiki files
# haiqinma - 20251029 - first version

set -u
set -o pipefail

LOGFILE_PATH="/var/log"
LOGFILE_NAME="periodic-bakup-wiki.log"
LOGFILE="$LOGFILE_PATH/$LOGFILE_NAME"
if [[ ! -d  "$LOGFILE_PATH" ]]
then
    mkdir -p "$LOGFILE_PATH"
fi


touch "$LOGFILE"

filesize=$(stat -c "%s" "$LOGFILE" )
if [[ "$filesize" -ge 1048576 ]]
then
    echo -e "clear old logs at $(date) to avoid log file too big" > "$LOGFILE"
fi


can_ssh_login() {
    local login_user="$1"
    local login_host="$2"

    if [[ -z "$login_user" || -z "$login_host" ]]; then
        echo "ERRROR: login user and ip address are necessary" >&2
        return 1
    fi

    ssh -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o PreferredAuthentications=publickey \
        "${login_user}@${login_host}" true &>/dev/null

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}


index=1
echo -e "\nstep $index -- This is the begining of bakup wiki. [$(date)] " | tee -a "$LOGFILE"

REMOTE_USER="root"
WIKI_HOST="159.138.36.164"
if can_ssh_login "${REMOTE_USER}" "${WIKI_HOST}"; then
	echo -e "the ${WIKI_HOST} could be ssh within 10 seconds"  | tee -a "$LOGFILE"
else
	echo -e "ERROR! the host ${WIKI_HOST} could not be ssh within 10 seconds right now [$(date)]"  | tee -a "$LOGFILE"
	exit 1
fi

KEEP_NUMBER=7
LOCAL_BACKUP_DIRECTORY="/root/bak/bak_wiki/"
if [ ! -d "$LOCAL_BACKUP_DIRECTORY" ]; then
    echo "directory is used to bakup wiki $LOCAL_BACKUP_DIRECTORY does no exist！" | tee -a "$LOGFILE"
    exit 2
fi

BACKUP_DIRS_COUNT=$(find "$LOCAL_BACKUP_DIRECTORY" -maxdepth 1 -type d -name "backup*" | wc -l)
if [ "$BACKUP_DIRS_COUNT" -gt "$KEEP_NUMBER" ]; then
	echo "there are many backup files, clear the files $KEEP_NUMBER days ago" | tee -a "$LOGFILE"
	find "$LOCAL_BACKUP_DIRECTORY" -maxdepth 1 -type d -name "backup*" -mtime +7 -exec rm -rf {} \;
fi


backup_directory_name="backup"$(date +%Y%m%d-%H%M%S)
index=$((index+1))
echo -e "\nstep $index -- backup wiki files" | tee -a "$LOGFILE"
local_backup_wiki=${LOCAL_BACKUP_DIRECTORY}/${backup_directory_name}/wiki
mkdir -p ${local_backup_wiki}
WIKI_NEED_BACKUP=(
	"/root/code/yeying-tool/tool/bookstack/data"
	"/root/code/yeying-tool/tool/bookstack/packages"
	"/root/code/yeying-tool/tool/bookstack/.env"
)
for item in "${WIKI_NEED_BACKUP[@]}"; do
	echo "bakup wiki files: ${item}" | tee -a "$LOGFILE"
	if [[ "$item" == *env ]]; then
		dest="${local_backup_wiki}/env"
	else
		dest="${local_backup_wiki}"
	fi
	if ! scp -r "${REMOTE_USER}@${WIKI_HOST}:${item}" "${dest}" ; then
		echo "ERROR! Failed to copy $item" | tee -a "$LOGFILE"
	fi
done


index=$((index+1))
echo -e "\nstep $index -- backup mysql files" | tee -a "$LOGFILE"
local_backup_mysql=${LOCAL_BACKUP_DIRECTORY}/${backup_directory_name}/mysql
mkdir -p ${local_backup_mysql}
MYSQL_NEED_BACKUP=(
	"/root/code/yeying-tool/middleware/mysql/data"
	"/root/code/yeying-tool/middleware/mysql/.env"
)
for item in "${MYSQL_NEED_BACKUP[@]}"; do
	echo "bakup mysql files: ${item}" | tee -a "$LOGFILE"
	if [[ "$item" == *env ]]; then
		dest="${local_backup_mysql}/env"
	else
		dest="${local_backup_mysql}"
	fi
	if ! scp -r "${REMOTE_USER}@${WIKI_HOST}:${item}" "${dest}" ; then
		echo "ERROR! Failed to copy $item" | tee -a "$LOGFILE"
	fi
done


echo -e "\nThis is the end of process wiki bakup operation. ====$(date)====" | tee -a "$LOGFILE"