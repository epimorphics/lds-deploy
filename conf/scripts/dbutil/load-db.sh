#!/bin/bash
# Load a constructed, compressed TDB database to a server for deployment with local dbinstall
#     load_db.sh  serverDir   imageFile

set -o errexit

[[ $# = 2 ]] || { echo "Internal error calling load_db.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly serverDir=$1
readonly imageFile=$2
readonly fileName=$(basename $imageFile)
readonly remoteDir=/home/ubuntu/deploy/dbload

IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)

echo "Uploading $fileName to server $IP"
scp -Cq $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem $imageFile ubuntu@${IP}:$remoteDir/$fileName

ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "sudo bash /usr/local/bin/dbinstall $remoteDir/$fileName"

# Delay a little to allow remote server to restart
sleep 8s
