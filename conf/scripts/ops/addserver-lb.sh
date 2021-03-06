#!/bin/bash
# Add a server to the tier load balancer if any
#       addserver-lb.sh  serverDirectory

set -o errexit

. /opt/dms/conf/scripts/config.sh
. /opt/dms/conf/scripts/lib.sh
CheckInstalls

[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }

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
