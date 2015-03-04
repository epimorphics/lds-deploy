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

    # Record status in S3 status already
    if [[ $tierDir =~ /var/opt/dms/(.*) ]]; then
        s3key="$S3_STATE/${BASH_REMATCH[1]}"
        aws s3 rm "$tierDir/lb-name"
        aws s3 rm "$tierDir/aws-lb.json"
    fi

else
    echo "No load balancer found" 1>&2
fi

