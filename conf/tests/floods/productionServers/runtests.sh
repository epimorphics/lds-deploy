#!/bin/bash
# Integration tests for a floods server
# Assumes run by tomcat7 user
# Argument:address of the server under test

set -o errexit
set -o pipefail

[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

probe() {
    curl -s "http://$IP/flood-monitoring/$1"
}

report_error() {
    echo "Test failed: $1"
    exit 1
}

(( $( probe "data/readings.csv?latest" | wc -l ) > 1000 ))   || report_error "Not enough readings"
[[ $( probe "id/floods" | jq ".items" ) != "null" ]]         || report_error "No items in flood warnings"
(( $( probe "id/floodAreas.csv?_limit=10" | wc -l ) > 9 ))   || report_error "Not enough flood areas"
