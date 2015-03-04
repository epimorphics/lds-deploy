#!/bin/bash
# Reset the database on a server to the latest external image plus all updates
# Primiarly to implement load step on a new server
# If applied to a live server all current data will be lost
# args: serverDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling resetServerData.sh" 1>&2 ; exit 1 ; }
. /opt/dms/conf/scripts/config.sh

readonly serverDir=$1

IP=$(jq -r ".address" < $serverDir/config.json)
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"

echo "Calling db_reset on $serverDir"
ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/db_reset
