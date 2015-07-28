#!/bin/bash
# Reset the data for all servers in a data tier
# For use from within DMS (must be run as tomcat user)
# args: tierDir or pass in from environment

set -o errexit

if [[ $# = 1 ]]; 
then
    tierDir="$1"
fi
[[ -n $tierDir ]] || { echo "Internal error calling resetTierData.sh, no tier given" 1>&2 ; exit 1 ; }

. /opt/dms/conf/scripts/config.sh
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"

for server in $tierDir/servers/*
do
    if grep -qv Terminated $server/status 
        then
        IP=$( jq -r .address "$server/config.json" )
        echo "Calling db_reset on $server"
        ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/db_reset
    fi
done
