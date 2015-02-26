#!/bin/bash
# Bring a set of servers in a tier up to date with the configured server state
# For use from within DMS (must be run as tomcat user)
# args: tierDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling tierCatchupState.sh" 1>&2 ; exit 1 ; }
. /opt/dms/conf/scripts/config.sh

readonly tierDir=$1

FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"

for server in $tierDir/servers/*
do
    if grep -qv Terminated $server/status 
        then
        IP=$( jq -r .address "$server/config.json" )
        echo "Calling dms-update on $server"
        ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/dms-update --perform
    fi
done
