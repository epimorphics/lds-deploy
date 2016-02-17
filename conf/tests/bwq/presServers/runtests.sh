#!/bin/bash
# Server tests for a BWQ presentation server

[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

check() {
    [[ $# = 3 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
    local NAME=$1
    local RESULT=$2
    local LIMIT=$3
    echo "Checking $NAME"
    if (( $RESULT < $LIMIT )); then
        echo "Failed, testing for: $NAME"
        return 1
    else
        return 0
    fi
}

checkAll() {
    check "Elda running" $(curl -s -H "Host: localhost" http://$IP/doc/bathing-water.json?_pageSize=5 | jq -r ".result.items | length") 5     
&&  check "Landing page non-trivial" $(curl -s -H "Host: localhost" http://$IP/bwq/profiles/ | grep "<div" | wc -l ) 10 
&&  check "Widget design page non-trivial" $(curl -s -H "Host: localhost"  http://$IP/bwq/widget/design | grep "<div" | wc -l ) 10
}

sleep 5s

if !checkAll ; then
    echo "Failed first try, retry after wait"
    sleep 15s
    if ! checkAll ; then
        echo "Failed tests"
        exit 1
    fi
fi

exit 0
