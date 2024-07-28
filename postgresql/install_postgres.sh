#!/usr/bin/env bash
# this script is used to install postgresql and make configuration on Ubuntu
# whereis psql
# psql: /usr/bin/psql /usr/share/man/man1/psql.1


# 20240712 - mahaiqing - first version
# 20240721 - mahaiqing - add clean database operation

set -u
set -o pipefail

SCRIPT_PATH=$(cd "$(dirname "$0")" || exit ;pwd)
LOGFILE_PATH="$SCRIPT_PATH/logs"
LOGFILE_NAME="12-software-install-postgresql.log"
LOGFILE="$LOGFILE_PATH/$LOGFILE_NAME"

if [[ ! -d  "$LOGFILE_PATH" ]]
then
    mkdir -p "$LOGFILE_PATH"
    echo -e "creat directroy($LOGFILE_PATH) to save log($LOGFILE_NAME)  [$(date)] " | tee "$LOGFILE"
else
    echo "This is going to install postgresql service packages on host $(hostname) [$(date)] " | tee "$LOGFILE"
fi

index=1
os_type=$(grep 'PRETTY_NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
echo -e "\nstep $index -- install postgresql on ${os_type} " | tee -a "$LOGFILE"


index=$((index+1))
echo -e "\nstep $index -- check software expect installed or not " | tee -a "$LOGFILE"
if [[ -e /usr/bin/expect ]]
    then
    echo "--package expect($results) has already installed." | tee -a "$LOGFILE"
elif [[ "$os_type" =~ "Ubuntu"  ]]
    then
    echo "This is going to install package(expect) on ${os_type}." | tee -a "$LOGFILE"
    sudo apt-get install -y expect
else
    echo  "You have to install package(expect) on ${os_type} manually." | tee -a "$LOGFILE"
    exit 1
fi


index=$((index+1)) 
echo -e "\nstep $index -- check software postgresql installed or not " | tee -a "$LOGFILE"
if [[ -e /usr/bin/psql ]]
    then
    echo "--package postgresql($results) has already installed." | tee -a "$LOGFILE"
elif [[ "$os_type" =~ "Ubuntu"  ]]
    then
    echo "This is going to install package(postgresql-14  net-tools) on ${os_type}." | tee -a "$LOGFILE"
    sudo apt-get install -y postgresql-14 net-tools
else
    echo  "You have to install package(postgresql) on ${os_type} manually." | tee -a "$LOGFILE"
    exit 1
fi


index=$((index+1))
echo -e "\nstep $index -- set service to autostart" | tee -a "$LOGFILE"
sudo systemctl enable postgresql@14-main.service
 


function create_database_for_yeying() {
sudo su - postgres <<EOF
psql


CREATE USER yeying WITH PASSWORD 'yytest';

CREATE DATABASE yeying OWNER yeying;

GRANT ALL PRIVILEGES ON DATABASE yeying TO yeying;

\c yeying;

CREATE TABLE network_identity(
    id          serial primary key not null,
    network     varchar(64)        not null,
    address     varchar(128)       not null,
    did         varchar(128)       not null,
    category    varchar(32)        not null default 'humanity',
    code        varchar(32)        not null default 'personal',
    name        varchar(128)       not null,
    extend      text               not null,
    update_time timestamp          not null default now(),
    CREATE_time timestamp          not null default now(),
    parent      varchar(128)
);

CREATE INDEX idx_identity_category ON network_identity (category);
CREATE INDEX idx_identity_code ON network_identity (code);
CREATE INDEX idx_identity_parent ON network_identity (parent);
CREATE UNIQUE INDEX uk_identity_did ON network_identity (did);
ALTER TABLE network_identity OWNER TO yeying;

CREATE TABLE node_application(
    id              serial primary key not null,
    uid             varchar(128)    not null,
    version         varchar(16)     not null,
    name            varchar(128)    not null,
    code            varchar(128)    not null,
    description     varchar(128)    not null,
    status          varchar(64)     not null,
    path            varchar(256)    not null,
    publisher       varchar(128)    not null,
    service_codes   text            not null,
    extend          text            not null,
    CREATE_time     timestamp       not null default now(),
    update_time     timestamp       not null default now()
);
CREATE INDEX idx_application_code ON node_application (code);
CREATE UNIQUE INDEX uk_application_uid ON node_application (uid);

ALTER TABLE node_application OWNER TO yeying;
 

CREATE TABLE node_invitation(
    id              serial primary key not null,
    scene           varchar(32)     not null default 'register',
    code            varchar(128)    not null,
    expired_time    timestamp       not null,
    service_did     varchar(128)    not null,
    inviter         varchar(128)    not null default 'system',
    invitee         varchar(128),
    CREATE_time     timestamp       not null default now(),
    update_time     timestamp       not null default now()
);

COMMENT ON COLUMN node_invitation.code IS '邀请码';
COMMENT ON COLUMN node_invitation.CREATE_time IS '创建时间';
COMMENT ON COLUMN node_invitation.expired_time IS '邀请码有效截止时间';
COMMENT ON COLUMN node_invitation.invitee IS '受邀方';
COMMENT ON COLUMN node_invitation.inviter IS '邀请方';
COMMENT ON COLUMN node_invitation.scene IS '邀请码使用场景';
COMMENT ON COLUMN node_invitation.service_did IS '要加入的供应商DID';
COMMENT ON COLUMN node_invitation.update_time IS '更新时间';
CREATE INDEX idx_invitation_invitee on node_invitation (invitee);
CREATE UNIQUE INDEX uk_invitation_code on node_invitation (code);

ALTER TABLE node_invitation OWNER TO yeying;
 

CREATE TABLE node_task
(
    id              serial primary key not null,
    uid             varchar(128)    not null,
    creator         varchar(128)    not null,
    code            varchar(64)     not null,
    content         varchar(128)    not null,
    initiator       varchar(128)    not null,
    operator        text            not null,
    status          varchar(64)     not null,
    extend          text            not null,
    CREATE_time     timestamp       not null default now(),
    update_time     timestamp       not null default now()
);

CREATE UNIQUE INDEX uk_task_uid ON node_task (uid);

ALTER TABLE node_task OWNER TO yeying;

CREATE TABLE node_user(
    id          serial primary key not null,
    service_did varchar(128)       not null,
    role        varchar(64)        not null default 'USER_ROLE_NORMAL',
    name        varchar(128)       not null,
    did         varchar(128)       not null,
    telephone   varchar(20)        not null,
    email       varchar(320)       not null,
    status      varchar(64)        not null default 'USER_STATUS_ACTIVE',
    extend      text               not null default '',
    update_time timestamp          not null default now(),
    CREATE_time timestamp          not null default now(),
    avatar      text               not null
);

CREATE INDEX idx_user_email ON node_user (email);
CREATE INDEX idx_user_name ON node_user (name);
CREATE INDEX idx_user_telephone ON node_user (telephone);
CREATE UNIQUE INDEX uk_user_did ON node_user (did);

ALTER TABLE node_user OWNER TO yeying;


\q
exit
EOF
}

index=$((index+1)) 
echo -e  "\nstep $index -- make database configuration for yeying " | tee -a "$LOGFILE"
sudo systemctl start postgresql@14-main.service
create_database_for_yeying


echo "This is end of install postgresql on host $(hostname) [$(date)] " | tee  -a "$LOGFILE"
