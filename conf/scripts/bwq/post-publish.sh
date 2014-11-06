#!/bin/bash
# Post-publication actions for the BWQ service
# Arguments:
#     serversDir (for data servers)


set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serversDir="/var/opt/dms/$1"

echo "Synchronizing web content, including source/dump files"
cd $serversDir/../..
for server in tiers/presServers/servers/* 
do
    FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
    echo "Sync to $server"
    IP=$( jq -r .address "$server/config.json" )
    rsync -a --delete -e "ssh $FLAGS" Web ubuntu@$IP:/var/www/environment/html

    echo "Clear caches"
    ssh -t -t $FLAGS -l ubuntu $IP sudo /usr/local/bin/ps_cache_clean 
    # ssh -t -t $FLAGS -l ubuntu $IP sudo /usr/sbin/htcacheclean -l1b -t -p/var/cache/apache2/mod_cache_disk
done

