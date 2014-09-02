#!/bin/bash
# Generic test of a data server. Only works in server has a public IP and opens port 3030, which ours don't
#       dataserver-test.sh serverdir
set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }

readonly serverDir=$1

cd $serverDir
readonly LOAD_BALANCER=$(jq -r ".DNSName" < ../../aws-lb.json)
status=$( curl -s4 -o /dev/null -w "%{http_code}" $LOAD_BALANCER/ds/query?query=SELECT%20*%20WHERE%20%7B%3Fs%20%3Fp%20%3Fo%7D%20LIMIT%201 )

if [[ $status != "200" ]] ; then
    echo "Test query returned status: $status"
    exit 1
else
    exit 0
fi
