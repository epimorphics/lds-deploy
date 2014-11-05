#!/bin/bash
# Post-publication actions for the BWQ service
# Arguments:
#     serversDir
#     server

set -o errexit
[[ $# = 2 ]] || { echo "Internal error calling $0.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serversDir="/var/opt/dms/$1"
readonly server="$2"

echo "Post-publication script called on $server"

readonly IP=$( jq -r .address "$serversDir/servers/$server/config.json" )

rsync -a --delete -e "ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem" "$serversDir/../../Web" ubuntu@$IP:/var/www/environment/html
