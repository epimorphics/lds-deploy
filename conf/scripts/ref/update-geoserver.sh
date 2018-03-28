#!/bin/bash
# Synchronize the configuration and cache for a geoserver instance

set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serverDir="$1"

FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
IP=$( jq -r .address "$serverDir/config.json" )
ssh -t -t $FLAGS -l ubuntu $IP sudo /usr/local/bin/update_geoserver
