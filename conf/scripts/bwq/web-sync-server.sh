#!/bin/bash
# Web sync operation for single server
# Arguments:
#     serverDir

set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serverDir="$1"

echo "Synchronizing web content, including source/dump files"
cd $serverDir/../../../../Web
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
IP=$( jq -r .address "$serverDir/config.json" )
rsync -a --delete -e "ssh $FLAGS" * ubuntu@$IP:/var/www/environment/html
