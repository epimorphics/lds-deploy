#!/bin/bash
# Integration tests for an epr server
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

(( $( probe "public-register/api/search.csv?name-number-search=smith" | wc -l ) > 10 ))   || report_error "Suspiciously few entries for smith"
