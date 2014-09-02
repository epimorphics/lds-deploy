#!/bin/bash
# Load a constructed, compressed TDB database to a server for deployment with local dbinstall
#     load_db.sh  serverDir   imageFile

set -o errexit

[[ $# = 2 ]] || { echo "Internal error calling load_db.sh" 1>&2 ; exit 1 ; }

readonly serverDir=$1
readonly imageFile=$2
readonly fileName=$(basename $imageFile)

IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)

echo "Uploading $fileName to server $IP"
scp -4Cq -o BatchMode=yes -o StrictHostKeyChecking=no -i /var/opt/dms/.ssh/lds.pem $imageFile ubuntu@${IP}:/tmp

ssh -4 -t -t -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "sudo bash /usr/local/bin/dbinstall /tmp/$fileName"
