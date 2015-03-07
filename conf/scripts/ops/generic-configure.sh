#!/bin/bash
# Experimental shell provisioning for pubservers
#    script  $serverDir

# Environment settings:
#    NRC_HOSTGROUP    - nagios host group to join
#    NRC_SERVICESET   - set of services to be checked by nagios
#    NRC_SERVICE      - list of nagios service names, used when terminating

set -o nounset
set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly serverDir=$1

server=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)
IP=$(jq -r ".Instances[0].PrivateIpAddress" < $serverDir/aws-instance.json)

#cd ../chef
#knife solo cook ubuntu@$IP $serverDir/node.json --identity-file /var/opt/dms/.ssh/lds.pem --yes --no-color

# Kick chef into action, assumes not already registered with server
ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem ubuntu@$server sudo chef-client -F min --no-color

# Install in nagios
FULL_NAME=$(jq -r .name < $serverDir/config.json)
NAME="$FULL_NAME"
if [[ $NAME =~ -([^-]*)$ ]] ; then NAME="${BASH_REMATCH[1]}"; fi

NRCAddHost "$FULL_NAME" "$NAME" $IP  "$NRC_HOSTGROUP" "$NRC_SERVICESET"  || echo "Nagios service not responding"

# Add server to S3 state backup
if [[ $serverDir =~ /var/opt/dms/(.*) ]]; then
    s3key="$S3_STATE/${BASH_REMATCH[1]}"
    aws s3 cp "$serverDir/status" "$s3key/status"
    aws s3 cp "$serverDir/config.json" "$s3key/config.json"
    aws s3 cp "$serverDir/aws-instance.json" "$s3key/aws-instance.json"
fi
