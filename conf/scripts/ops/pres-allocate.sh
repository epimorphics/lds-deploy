#!/bin/bash
# Start an AWS instance for a pubserver presentation tier
#    script  $serverDir

# Environment settings:
#    AWS_INSTANCE_TYPE        instance type to create
#    AWS_AMI                  AMI to use
#    AWS_INSTANCE_STORE=yes   allocate an instance store to ephemeral0
#    AWS_EBS=10               allocate an EBS of the given size 
#    CHEF_ROLE                name of the top level role for this instance

set -o errexit

. ./config.sh
. ./lib.sh
CheckInstalls

serverDir=$1

# Work out server name and placement
if [[ $serverDir =~ .*/services/(.*)/publicationSets/(.*)/tiers/(.*)/servers/(.*) ]]; then
    readonly FULL_NAME="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]}"
    readonly NAME="${BASH_REMATCH[4]}"
    echo "Allocating server $FULL_NAME"
else
    echo "Badly formed server directory: $serverDir" 1>&2
    exit 99;
fi

# AllocateServer "$serverDir"

# Work out query endpoint for corresonding data tier (assumes called dataservers)
LB_DNS=$( jq .DNSName $serverDir/../../../dataservers/aws-lb.json )
LB_QUERY="$LB_DNS/ds/query"
CHEF_PARAMS="{\"node\"{\"epi_presentation_server\"{\"services\"{\"environment\"{\"data_server_query_endpoint\":\"$LB_QUERY\"},\"location\":{\"data_server_query_endpoint\":\"$LB_QUERY\"}}}}}"
echo "CHEF_PARAMS = $CHEF_PARAMS"
# InstallChef "$serverDir"
#InstallChefSolo "$serverDir" "../chef"