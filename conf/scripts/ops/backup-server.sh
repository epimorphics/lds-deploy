#!/bin/bash
# Backup the database from a running server
#     backup-server.sh  serverDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling backup-server.sh" 1>&2 ; exit 1 ; }

readonly serverDir=$1
readonly server=$( basename $serverDir )

IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)

echo "Starting backup on server $server"
remoteFile=$( ssh -4 -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "bash /usr/local/bin/dbbackup" )
filename="$server-$( basename $remoteFile )"

echo "Finished, transfering file to control server"
cd $serverDir/../../../../images
scp -4Cq -o BatchMode=yes -o StrictHostKeyChecking=no -i /var/opt/dms/.ssh/lds.pem ubuntu@${IP}:$remoteFile $filename

echo "Removing backup from server $server"
ssh -4 -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "sudo rm $remoteFile"

echo $PWD/$filename
