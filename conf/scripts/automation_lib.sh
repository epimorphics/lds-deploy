#!/bin/bash
# Function library used in external automation scripts
# Generally assume runing as tomcat7 for compatbility with DMS UI calling

# Find the first live server in a tier
# Usage: firstLiveServer  tier
firstLiveServer() {
    [[ $# = 1 ]] || { echo "Internal error calling firstLiveServer" 1>&2 ; exit 1 ; }
    local tierDir="$1"

    for server in $tierDir/servers/*
    do
        if grep -qv Terminated $server/status ; then
            echo $server
            exit 0
        fi
    done
    exit 1
}

# Backup a server to both local disk and to S3
# Usage: backupServer serverDir s3folder
backupServer() {
    [[ $# = 2 ]] || { echo "Internal error calling backupServer" 1>&2 ; exit 1 ; }
    local serverDir="$1"
    local s3folder="$2"

    cd /opt/dms/conf/scripts
    backupFile=$( sudo -u tomcat7 ops/backup-server.sh $serverDir | tail -1 )

    echo "Publish to S3 images area"
    if [[ $backupFile =~ .*/images/[^-_]+-[^_]+_([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])_([0-9][0-9]-[0-9][0-9]-[0-9][0-9]).nq.gz ]]; then
        date=${BASH_REMATCH[1]}
        time=${BASH_REMATCH[2]}
        aws s3 cp $backupFile $s3folder/images/$date/$time-0000/backupServer_dump.ng.gz
    else
        echo "Badly formed backup file name, omitting S3 publish - $backupFile"
        exit 1
    fi
}

# Backup the first live server in a tier to both local disk and to S3
# Usage: backupTier tierDir s3folder
backupTier() {
    [[ $# = 2 ]] || { echo "Internal error calling backupTier" 1>&2 ; exit 1 ; }
    local tierDir="$1"
    local s3folder="$2"
    local serverDir=$( firstLiveServer $tierDir )
    backupServer $serverDir $s3folder
}

