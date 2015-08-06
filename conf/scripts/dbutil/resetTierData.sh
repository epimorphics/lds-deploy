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
        ops/removeserver-lb.sh $server

        IP=$( jq -r .address "$server/config.json" )
        echo "Calling db_reset on $server"
        echo ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/db_reset

        if [[ $tierDir =~ /var/opt/dms/services/(.*)/publicationSets/(.*)/tiers/(.*) ]]; then
            service="${BASH_REMATCH[1]}"
            testRunner="/opt/dms/conf/tests/$service/runtests.sh"
            if [[ -x "$testRunner" ]]; then
                $testRunner || { echo "Tests failed, aborting with $server out of LB" 1>&2 ; exit 1 ; }
            fi
        fi

        ops/addserver-lb.sh $server
    fi
done
