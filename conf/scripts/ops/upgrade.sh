#!/bin/bash
# Full update - assumes update testing on some dev/test machine 

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling $0, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

. /opt/dms/conf/scripts/config.sh

ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo apt-get -yq update
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo apt-get -yq upgrade
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo apt-get -yq dist-upgrade
