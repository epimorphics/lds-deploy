#!/bin/bash
# Integration tests for an epr server
# Assumes run by tomcat7 user
# Argument:address of the server under test

set -o errexit
set -o pipefail

. /opt/dms/conf/scripts/config.sh

[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

probe() {
    curl -s "http://$IP/$1"
}

report_error() {
    echo "Test failed: $1"
    exit 1
}

checkAll() {
    local RESULT=$( probe "public-register/api/search.csv?name-number-search=smith" | wc -l )
    local LIMIT=10
    if (( $RESULT < $LIMIT )); then
        echo "Failed, suspiciously few entries for smith"
        return 1
    else
        return 0
    fi    
}

sleep 5s

echo "Clear cache on $SERVER"
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
ssh -t -t $FLAGS -l ubuntu $IP sudo /usr/local/bin/ps_cache_clean

if ! checkAll ; then
    echo "Failed first try, retry after wait"
    sleep 15s
    if ! checkAll ; then
        echo "Failed tests"
        exit 1
    fi
fi
