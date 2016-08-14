#!/bin/bash
# Run cucumber integration tests for CDE servers
[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

export TEST_HOST=$IP
cd /opt/dms/conf/tests/cde/ea_cde_pub/test/cucumber
if ! bundle check ; then
    bundle install
fi
bundle exec cucumber
