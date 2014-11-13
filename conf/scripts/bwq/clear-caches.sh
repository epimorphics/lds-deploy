#!/bin/bash
# Clear the presentation server caches
# Arguments:
#     serversDir


set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serversDir="$1"

for server in $serversDir/servers/* 
do
    if grep -qv Terminated $server/status 
    then
        FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
        IP=$( jq -r .address "$server/config.json" )
        echo "Clear cache on $server"
        ssh -t -t $FLAGS -l ubuntu $IP sudo /usr/local/bin/ps_cache_clean 
    fi
done

