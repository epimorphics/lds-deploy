#!/bin/bash
# Initialize a new server using stored S3 state
# args: serverDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling catchupState.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serverDir=$1

IP=$(jq -r ".address" < $serverDir/config.json)
echo "Calling dms-update on $serverDir"
ssh -t -t $FLAGS -l ubuntu $IP /bin/bash /usr/local/bin/dms-update --perform
