#!/usr/bin/env bash
# this script is used to clean postgresql and make configuration on Ubuntu
# whereis psql
# psql: /usr/bin/psql /usr/share/man/man1/psql.1


# 20240727 - mahaiqing - first version


set -u
set -o pipefail

SCRIPT_PATH=$(cd "$(dirname "$0")" || exit ;pwd)
LOGFILE_PATH="$SCRIPT_PATH/logs"
LOGFILE_NAME="14-clean-postgresql.log"
LOGFILE="$LOGFILE_PATH/$LOGFILE_NAME"

if [[ ! -d  "$LOGFILE_PATH" ]]
then
    mkdir -p "$LOGFILE_PATH"
    echo -e "creat directroy($LOGFILE_PATH) to save log($LOGFILE_NAME)  [$(date)] " | tee "$LOGFILE"
else
    echo "This is going to clean postgresql service on host $(hostname) [$(date)] " | tee "$LOGFILE"
fi

index=1
os_type=$(grep 'PRETTY_NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
echo -e "\nstep $index -- clean postgresql on ${os_type} " | tee -a "$LOGFILE"


index=$((index+1))
echo -e "\nstep $index -- check software expect installed or not " | tee -a "$LOGFILE"
if [[ -e /usr/bin/expect ]]
    then
    echo "--package expect($results) has already installed." | tee -a "$LOGFILE"
elif [[ "$os_type" =~ "Ubuntu"  ]]
    then
    echo "This is going to clean package(expect) on ${os_type}." | tee -a "$LOGFILE"
    sudo apt-get install -y expect
else
    echo  "You have to clean package(expect) on ${os_type} manually." | tee -a "$LOGFILE"
    exit 1
fi


index=$((index+1)) 
echo -e "\nstep $index -- check software postgresql installed or not " | tee -a "$LOGFILE"
if [[ ! -e /usr/bin/psql ]]
    then
    echo "--package postgresql($results) has not been installed. There is no need to clean database." | tee -a "$LOGFILE"
    exit 0
fi



function drop_database_for_yeying() {
sudo su - postgres <<EOF
psql

REVOKE ALL ON DATABASE yeying FROM yeying;

DROP DATABASE IF EXISTS yeying;

DROP OWNED BY yeying CASCADE;

DROP ROLE IF EXISTS yeying;
\q
exit
EOF
}

index=$((index+1)) 
echo -e  "\nstep $index -- clean database configuration for yeying " | tee -a "$LOGFILE"
sudo systemctl start postgresql@14-main.service
drop_database_for_yeying
sudo systemctl restart postgresql@14-main.service

echo "This is end of clean postgresql on host $(hostname) [$(date)] " | tee  -a "$LOGFILE"
