#!/bin/bash
# Server tests for a BWQ presentation server

[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

check() {
    local NAME=$1
    local LIMIT=$2
    local RESULT=${3:-0}
    echo "Checking $NAME"
    if (( $RESULT < $LIMIT )); then
        echo "Failed, testing for: $NAME"
        return 1
    else
        return 0
    fi
}

checkAll() {
      check "Elda running" 5 $(curl -s -H "Host: localhost" http://$IP/doc/bathing-water.json?_pageSize=5 | jq -r ".result.items | length")  \
  &&  check "Landing page non-trivial" 10 $(curl -s -H "Host: localhost" http://$IP/bwq/profiles/ | grep "<div" | wc -l ) \
  &&  check "Widget design page non-trivial" 10 $(curl -s -H "Host: localhost"  http://$IP/bwq/widget/design | grep "<div" | wc -l )
}

sleep 5s

if ! checkAll ; then
    echo "Failed first try, retry after wait"
    sleep 15s
    if ! checkAll ; then
        echo "Failed tests"
        exit 1
    fi
fi

exit 0
