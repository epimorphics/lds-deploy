#!/bin/bash
# Terminate a server
#    script serverDir
#
# Environment settings:
#    NRC_SERVICE      - list of nagios service names, used when terminating

set -o nounset
set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly serverDir=$1
readonly instanceID=$(jq -r ".Instances[0].InstanceId" < $serverDir/aws-instance.json)
readonly nodeName=$(jq -r ".name" < $serverDir/config.json)

# Stop rather full terminate to allow for recovery from mistakes ...
# state=$(aws ec2 stop-instances --instance-ids $instanceID | jq -r ".StoppingInstances[0].CurrentState.Name")

echo "Terminating $serverDir"
state=$(aws ec2 terminate-instances --instance-ids $instanceID | jq -r ".TerminatingInstances[0].CurrentState.Name")
echo "Instance is $state"

# Remove node from chef server (can be very slow)
knife node delete $nodeName -y -c /var/opt/dms/.chef/knife.rb 

FULL_NAME=$(jq -r .name < $serverDir/config.json)
NRCDeleteHost "$FULL_NAME" "$NRC_SERVICE" || echo "Nagios service not responding"

# Remove server from S3 state backup
if [[ $serverDir =~ /var/opt/dms/(.*) ]]; then
    s3key="$S3_STATE/${BASH_REMATCH[1]}"
    aws s3 rm "$s3key/status"  || true
    aws s3 rm "$s3key/config.json" || true
    aws s3 rm "$s3key/aws-instance.json" || true
fi
