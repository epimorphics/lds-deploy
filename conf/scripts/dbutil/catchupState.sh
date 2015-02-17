#!/bin/bash
# Bring a single server up to date with the configured server state
# args: serverDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling catchupState.sh" 1>&2 ; exit 1 ; }
. /opt/dms/conf/scripts/config.sh

readonly serverDir=$1

IP=$(jq -r ".address" < $serverDir/config.json)
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"

echo "Calling dms-update on $serverDir"
ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/dms-update --perform
