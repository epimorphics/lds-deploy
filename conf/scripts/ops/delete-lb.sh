#!/bin/bash
# Delete the load balancer for a tier
#       delete-lb.sh  tierDirectory

set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly tierDir=$1

if [[ -f $tierDir/lb-name ]]; then
    readonly NAME=$(cat $tierDir/lb-name)
    echo "Deleting load balancer $NAME"
    aws elb delete-load-balancer --load-balancer-name "$NAME"
    rm $tierDir/aws-lb.json $tierDir/lb-name
else
    echo "No load balancer found" 1>&2
fi

