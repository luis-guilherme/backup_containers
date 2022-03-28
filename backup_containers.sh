#!/bin/bash
# Backup containers from all my podman containers into my backup host (e.g. a remote host, a Synology NAS, a NAS, etc.)
# ---------------------------------------------------------------------------
# + configured via bash variables below
# USE AT YOUR OWN RISK! It may delete files on the backup host!
# Assumptions:
# - I have a backup host (e.g. a remote host, a Synology NAS, a NAS, etc.) that runs a cron job to backup my containers
#  - source host account has passwordless ssh login (with key) (ssh-copy-id user@host)
#  - source host account has sudo with no password for tar command (echo "username ALL=(ALL) NOPASSWD: /usr/bin/tar" | sudo tee -a /etc/sudoers.d/username)
#  - destination host has xz in path
#  - no error control is done on the source host, if it fails, it fails. There are stop and start files to know if the container is running or not
#  - containers are running under podman, and each application has all containers inside a pod with the name of the app. containers are then named with suffixes as -app, -db, etc
#  - I run my containers as non root on a standard /home/username/podman-podname/ folder structure. This allows me to include on the .ini file only the hostname, the pod name and the exclude patterns
#  - structure of the .ini file is: hostname;podname;exclude pattern;include pattern;source directory (separated by ;)
#  - I keep only the last 30 days of backups of each container

USERNAME=username
BACKUPS_FILE="backups.ini"
DATE=$(date '+%Y-%m-%d')
BASEBACKUPPATH=/volume4/Backups/Containers
BASESOURCEPATH=/home/username/podman-
BACKUPDAYS=+30

[ ! -f ${BACKUPS_FILE} ] && echo "File with list of backups is missing. Exiting..." && exit 1 
echo "Reading backups list..."
mapfile -t lines < <(tee /dev/tty <${BACKUPS_FILE})
echo ${#lines[@]}
for i in "${lines[@]}"
do
    IFS=';' read -r -a backup <<< "$i"

    HOST=${backup[0]}
    PODNAME=${backup[1]}

    # Make sure the exclude is a valid exclude={xxxx} tar string array (with single quotes)
    EXCLUDE=${backup[3]}
    [[ -z ${EXCLUDE} ]] && EXCLUDE="'*.log'";

    # Make sure the include is a valid tar include
    INCLUDE=${backup[4]}
    [[ -z ${INCLUDE} ]] && INCLUDE="./*" && echo "adding default INCLUDE of ./*"

    # I run my containers on a standard folder /home/username/podman-podname/
    SOURCEDIR=$(eval "echo ${backup[2]}")
    [[ -z ${SOURCEDIR} ]] && SOURCEDIR=${BASESOURCEPATH}${PODNAME}/${INCLUDE}

    DESTFILE=${DATE}_${HOST}_${PODNAME}.tar.xz

    echo "Backing up container ${PODNAME} on ${HOST} from ${SOURCEDIR} to ${BASEBACKUPPATH}/${DESTFILE}..."
    [ ! -d ${BASEBACKUPPATH} ] && echo "Could not find destination backup folder. Exiting ..." && exit 1 || cd ${BASEBACKUPPATH}
    ssh ${USERNAME}@${HOST} "cd /home/lguilherme/podman-${PODNAME} && podman pod stop ${PODNAME} && touch podman-${PODNAME}.stop"
    ssh ${USERNAME}@${HOST} "cd /home/lguilherme/podman-${PODNAME} && sudo tar cfp - --exclude={$EXCLUDE} ./*" | xz -9 > ${BASEBACKUPPATH}/${DESTFILE}
    ssh ${USERNAME}@${HOST} "cd /home/lguilherme/podman-${PODNAME} && podman pod start ${PODNAME} && touch podman-${PODNAME}.start"
    
    find ${BASEBACKUPPATH} -name "*_${HOST}_${PODNAME}.tar.xz" -type f -mtime $BACKUPDAYS -exec rm -f {} \;

done