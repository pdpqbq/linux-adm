#!/usr/bin/env bash

LOCKFILE=/tmp/borg.lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "already running"
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Configure backup

BACKUP_HOST=192.168.100.20
BACKUP_USER=root
BACKUP_REPO=mm-files

echo $BACKUP_REPO

# minio mirror create
if [ -d /tmp/minio ]; then rm -rf /tmp/minio; fi
mkdir /tmp/minio; /opt/minio/mc mirror local/mattermost /tmp/minio

# Make backup
borg create \
  --stats --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"mm-{now:%Y-%m-%d_%H:%M:%S}" \
  /tmp/minio

# minio mirror remove
rm -rf /tmp/minio

# Prune backup
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-within=7d \
  --keep-monthly=3

# Delete lockfile
rm -f ${LOCKFILE}
