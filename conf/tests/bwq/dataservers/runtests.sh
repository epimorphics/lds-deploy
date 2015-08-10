#!/bin/bash
# Integration tests for bathing water data servers - assumes at least baseline and reference data included"

set -o errexit
set -o pipefail

[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

checkCount() {
    [[ $# = 2 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
    local QUERY=$1
    local LIMIT=$2
    local COUNT=$( curl -s http://$IP:3030/ds/query --data-urlencode "query=SELECT (COUNT(?x) AS ?count) WHERE { $QUERY }"  | jq -r ".results.bindings[0].count.value" )
    if [[ -z "$COUNT" ]]; then
        echo "Data test failed. Query '$QUERY' returned empty"
        exit 1
    fi
    if (( $COUNT < $LIMIT )); then
        echo "Data test failed. Query '$QUERY' returned only $COUNT instead of $LIMIT"
        exit 1;
    fi
}

checkCount "GRAPH ?x {}" 10
checkCount "?x a <http://environment.data.gov.uk/def/bathing-water/BathingWater>" 50
