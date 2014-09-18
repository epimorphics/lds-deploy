#!/bin/bash
# Backup the database from a running server
#     backup-server.sh  serverDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling backup-server.sh" 1>&2 ; exit 1 ; }
. ./config.sh
. ./lib.sh

readonly serverDir=$1
readonly server=$( basename $serverDir )

IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)

echo "Starting backup on server $server"
remoteFile=$( ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "bash /usr/local/bin/dbbackup" )
filename="$server-$( basename $remoteFile )"

echo "Finished, transfering file to control server"
mkdir -p $serverDir/../../../../images
cd $serverDir/../../../../images
scp -Cq $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem ubuntu@${IP}:$remoteFile $filename

echo "Removing backup from server $server"
ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "sudo rm $remoteFile"

echo "Counting backup size to record in metrics"
size=$( gunzip -c $filename | wc -l)
echo "Counted $size quads"
if [[ $serverDir =~ .*/services/(.*)/publicationSets/(.*)/tiers/(.*)/servers/(.*) ]]; then
    tiername="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
else
    echo "Badly formed server directory: $serverDir" 1>&2
fi
SendMetric "dms.${tiername}.quadcount.max" $size || true

echo $PWD/$filename
