#!/bin/bash
# Bersion of post-publish script used for manual web content sync
# Arguments:
#     tier


set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serversDir="$1"

echo "Synchronizing web content, including source/dump files for $serversDir"
cd $serversDir/../../Web
for server in $serversDir/servers/* 
do
    if grep -qv Terminated $server/status 
    then
        FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
        echo "Sync to $server"
        IP=$( jq -r .address "$server/config.json" )
        rsync -a --delete -e "ssh $FLAGS" * ubuntu@$IP:/var/www/html

        echo "Clear caches"
        ssh -t -t $FLAGS -l ubuntu $IP sudo /usr/local/bin/ps_cache_clean 
    fi
done
