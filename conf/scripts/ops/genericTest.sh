#!/bin/bash
# Generic server test driver that locates the corresponding test script (if any) in the tests area

set -o errexit

[[ $# = 1 ]] || { echo "Error calling $0, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"

if [[ $SERVER =~ .*/services/(.*)/publicationSets/(.*)/tiers/(.*)/servers/(.*) ]]; then
    TEST="/opt/dms/conf/tests/${BASH_REMATCH[1]}/${BASH_REMATCH[3]}/runtests.sh"
    if [[ -x $TEST ]]; then
        echo "Running ${BASH_REMATCH[1]} - ${BASH_REMATCH[3]} integration tests"
        $TEST $SERVER
    else
        echo "No integration tests found"
    fi
fi
