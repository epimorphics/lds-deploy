#!/bin/bash
# Experimental shell provisioning for pubservers
#    script  $serverDir
set -o nounset
set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly serverDir=$1

IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)
#cd ../chef
#knife solo cook ubuntu@$IP $serverDir/node.json --identity-file /var/opt/dms/.ssh/lds.pem --yes --no-color

# Kick chef into action, assumes not already registered with server
ssh -i /var/opt/dms/.ssh/lds.pem ubuntu@$IP sudo chef-client -F min --no-color
