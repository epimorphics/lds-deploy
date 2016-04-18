#!/bin/bash
# Server tests for a WIMS server

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

checkDownload() {
    echo "Checking downloadAPI - SUPRESSED"
#    curl -s -H "Host: localhost" "http://$IP/bwq/downloadAPI/requestDownload?report=profile&district=Blackpool&from=2015-05-01&to=2015-06-01" > /tmp/download.zip \
#    && zip -Tq /tmp/download.zip
    return 0
}

checkAll() {
      check "API non trivial" 20 $(curl -s -H "Host: localhost" http://$IP/water-quality/def/sampling-point-types.json | jq -r ".result.items | length")  \
  &&  check "Landing page non-trivial" 10 $(curl -s -H "Host: localhost" http://$IP/water-quality/view/ | grep "<div" | wc -l ) 
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
