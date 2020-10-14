#!/bin/bash

# CONFIG START
SSH_HOST=host.example
SSH_PORT=22
SSH_USER=backup_user
SSH_KEY=path/to/sshkey
SSH_KNOWN_HOSTS=path/to/known_hosts
REMOTE_PATHS=( "/srv" )
LOCAL_PATH=/volume1/share_name/folder
# CONFIG END

NOW=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR=$(dirname "$0")/logs
LOG=$LOG_DIR/backup_$NOW.log

{
    mkdir -p $LOG_DIR
    touch $LOG

    echo [$(date +"%T")] Start Backup
    echo "SSH Target: $SSH_USER@$SSH_HOST:$SSH_PORT"
    echo "Paths to back up:"
    for path in "${REMOTE_PATHS[@]}"
    do
        echo "- $path"
    done
    echo "Backup location: $LOCAL_PATH"

    echo [$(date +"%T")] Moving existing backup to temporary location..
    TEMP_PATH=$(echo $LOCAL_PATH | sed 's:/*$::')_temp/
    [ ! -d "$LOCAL_PATH" ] && mkdir -p "$LOCAL_PATH"
    mv $LOCAL_PATH $TEMP_PATH

    ERROR_CODE=0
    for path in "${REMOTE_PATHS[@]}"
    do
        echo [$(date +"%T")] Syncing remote path $path..
        /bin/rsync -zrltR --delete --stats --human-readable \
            -e "ssh -i $SSH_KEY -p $SSH_PORT -o UserKnownHostsFile=$SSH_KNOWN_HOSTS" \
            $SSH_USER@$SSH_HOST:$path "$TEMP_PATH"
        ERROR_CODE=$(($ERROR_CODE + $?))
    done

    echo [$(date +"%T")] Copy synced backup back to "$LOCAL_PATH"..
    cp -R --preserve=timestamps ${TEMP_PATH} "${LOCAL_PATH}"
    rm -rf ${TEMP_PATH}

    echo [$(date +"%T")] Finished Backup
} 2>&1 | tee $LOG

exit $ERROR_CODE
