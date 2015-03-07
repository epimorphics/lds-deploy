#!/bin/bash
# Allocate a new load balancer for a tier
#       allocate-lb.sh  tierDirectory
# Environment parameters
#       LB_BACK_END=yes               - default is a front end group
#       LB_HEALTHCHECK=ping           - location to ping for health check, default is ping

set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

readonly tierDir=$1

# Work out server name and placement
if [[ $tierDir =~ .*/services/(.*)/publicationSets/(.*)/tiers/(.*) ]]; then
    readonly NAME="${BASH_REMATCH[1]:0:8}-${BASH_REMATCH[2]:0:8}-${BASH_REMATCH[3]:0:8}-LB"
    echo "Allocating load balancer $NAME"
else
    echo "Badly formed tier directory: $tierDir" 1>&2
    exit 99;
fi

SECURITY_GROUP=$SG_FRONT_END
if [[ $LB_BACK_END == yes ]]; then
    SECURITY_GROUP="$SG_BACK_END --scheme internal"
fi

# Check if there is already an allocated LB here
if [[ -f $tierDir/aws-lb.json && -f $tierDir/lb-name ]]; then
    echo "Load balancer config already exists, skipping allocation" 1>&2
    exit 0
else
    aws elb create-load-balancer --load-balancer-name "$NAME" \
        --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 \
        --subnets ${VPC_PUBLIC[*]} --security-groups $SECURITY_GROUP > $tierDir/aws-lb.json
fi

echo $NAME > $tierDir/lb-name

echo "Setting standard LB configuration"

# Standard health check config set LB_HEALTHCHECK to location to ping
aws elb configure-health-check --load-balancer-name "$NAME" \
    --health-check "Target=HTTP:80/${LB_HEALTHCHECK:-ping},Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3" > /dev/null

# Enable cross-zone balancing since we may have uneven distribution due to small numbers
# Enable conneciton draining over 60s so running queries get a chance to finish
# Set IdleTimeout to the default 60s so that it can be change later
aws elb modify-load-balancer-attributes --load-balancer-name "$NAME" \
    --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true},\"ConnectionDraining\":{\"Enabled\":true,\"Timeout\":60},\"ConnectionSettings\":{\"IdleTimeout\":60}}" > /dev/null

# Record status in S3 status already
if [[ $tierDir =~ /var/opt/dms/(.*) ]]; then
    s3key="$S3_STATE/${BASH_REMATCH[1]}"
    aws s3 cp "$tierDir/lb-name" "$s3key/lb-name"
    aws s3 cp "$tierDir/aws-lb.json" "$s3key/aws-lb.json"
fi
