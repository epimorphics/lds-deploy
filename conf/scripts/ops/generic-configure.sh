#!/bin/bash
# Experimental shell provisioning for pubservers
#    script  $serverDir
set -o nounset
set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly serverDir=$1

server=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)
IP=$(jq -r ".Instances[0].PublicIpAddress" < $serverDir/aws-instance.json)

#cd ../chef
#knife solo cook ubuntu@$IP $serverDir/node.json --identity-file /var/opt/dms/.ssh/lds.pem --yes --no-color

# Kick chef into action, assumes not already registered with server
ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem ubuntu@$server sudo chef-client -F min --no-color

# Install in nagios
if [[ $serverDir =~ .*/services/(.*)/publicationSets/(.*)/tiers/(.*)/servers/(.*) ]]; then
    readonly FULL_NAME="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]}"
    readonly NAME="${BASH_REMATCH[4]}"
else
    echo "Badly formed server directory: $serverDir" 1>&2
    exit 99;
fi
NRCAddHost "$FULL_NAME" "$NAME" $IP  "BWQ-data" "BWQ-data-ss"
