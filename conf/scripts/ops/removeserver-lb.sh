#!/bin/bash
# Remove a server from the tier load balancer if any
#       removeserver-lb.sh  serverDirectory

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
        echo "Removing $SERVER from load balancer $LBNAME"
        aws elb deregister-instances-from-load-balancer --load-balancer-name $LBNAME --instances $instanceID
        # ELB can take several 6-8s seconds to take effect
        sleep 10
    else 
        echo "Could not find server instance information at $serverDir" 1>&2
    fi
else
    echo "No load balancer found" 1>&2
fi
