#!/bin/bash
# Restart CDE tomcat instances to prevent memory/thread leak build up

set -o errexit
. /opt/dms/conf/scripts/config.sh

readonly serversDir="/var/opt/dms/services/cde/publicationSets/production/tiers/productionServers/servers"
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"

cd $serversDir
for server in *
    do
        if grep -q Running $server/status 
        then
            echo "Restart tomcat on $server"
            /opt/dms/conf/scripts/ops/removeserver-lb.sh $server || true
            IP=$( jq -r .address "$server/config.json" )
            ssh -t -t $FLAGS -l ubuntu $IP sudo service tomcat7 restart
            /opt/dms/conf/scripts/ops/addserver-lb.sh $server || true
        fi
    done
