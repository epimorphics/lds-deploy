#!/bin/bash
# Bring server up to date with the configured server state
# args: serverDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling catchupState.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serverDir=$1

IP=$(jq -r ".address" < $serverDir/config.json)
echo "Calling db_reset on $serverDir"
ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/db_reset
