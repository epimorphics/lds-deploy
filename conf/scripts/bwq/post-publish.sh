#!/bin/bash
# Post-publication actions for the BWQ service
# Arguments:
#     serversDir (for data servers)


set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serversDir="/var/opt/dms/$1"

echo "Synchronized web content, including source/dump files"
cd $serversDir/../..
for server in tiers/presServers/servers/* 
do
    echo "Sync to $server"
    IP=$( jq -r .address "$server/config.json" )
    rsync -a --delete -e "ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem" Web ubuntu@$IP:/var/www/environment/html
done
