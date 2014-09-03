#!/bin/bash

set -o nounset
set -o errexit

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
knife -c /var/opt/dms/.chef/knife.rb node delete $nodeName -y
