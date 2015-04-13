#!/bin/bash
# Add a server to the tier load balancer if any
#       addserver-lb.sh  serverDirectory

set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly serverDir=$1

if [[ -f $serverDir/../../lb-name ]]; then
    readonly LBNAME=$(cat $serverDir/../../lb-name)

    if [[ -f $serverDir/aws-instance.json ]]; then
        instanceID=$( jq -r '.Instances[0].InstanceId' < $serverDir/aws-instance.json )
        [[ $serverDir =~ .*/services/(.*)/publicationSets/(.*)/tiers/(.*)/servers/(.*) ]] && SERVER=${BASH_REMATCH[4]}
        echo "Adding $SERVER to load balancer $LBNAME"
        aws elb register-instances-with-load-balancer --load-balancer-name $LBNAME --instances $instanceID
        WaitForLB $LBNAME $instanceID InService
    else 
        echo "Could not find server instance information at $serverDir" 1>&2
    fi
else
    echo "No load balancer found" 1>&2
fi
