#!/bin/bash
# Web sync operation for whole tier
# Arguments:
#     tier (for presentation servers)


set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly tierDir="$1"

echo "Synchronizing web content, including source/dump files"
cd $tierDir/../../Web/asset-management/assets
for server in $tierDir/servers/* 
do
    if grep -qv Terminated $server/status 
    then
        FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
        echo "Sync to $server"
        IP=$( jq -r .address "$server/config.json" )
        rsync -a --delete -e "ssh $FLAGS" * ubuntu@$IP:/var/www/ref/html/asset-management/assets
    fi
done
