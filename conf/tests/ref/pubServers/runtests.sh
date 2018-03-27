#!/bin/bash
# Minimal integration test for Reference data servers

[[ $# = 1 ]] || { echo "Internal error calling runtests, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )



check() {
    local NAME=$1
    local LIMIT=$2
    local RESULT=${3:-0}
    echo "Checking $NAME"
    if (( $RESULT < $LIMIT )); then
        echo "Failed, testing for: $NAME - saw $RESULT"
        return 1
    else
        return 0
    fi
}

sqlCheck() {
    local SSH_FLAGS="-q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  -i /var/opt/dms/.ssh/lds.pem"
    ssh -t $SSH_FLAGS -l ubuntu $IP sudo -u postgres psql reference -q -P pager=off -t <<- EOF | grep asset | wc -l
SELECT uri from reference WHERE type = 'MaintainedAsset' LIMIT 5; 
EOF
}

checkAll() {
  check "Geoserver non-trivial login page"  10 $(curl -s -H "Host: environment.data.gov.uk" http://$IP/integrated-geo/web/ | grep '<li>' | wc -l)  &&
  check "Random geoserver tile"            500 $(curl -s -H "Host: environment.data.gov.uk" http://$IP/integrated-geo/gwc/service/tms/1.0.0/epimorphics:ref-maintained-assets@EPSG:900913@pbf/7/63/84.pbf | wc -l)  &&
  check "Asset API has assets"              10 $(curl -s -H "Host: environment.data.gov.uk" http://$IP/asset-management/id/asset.json?_limit=10 | jq -r ".items | length" ) &&
  check "Postgresql has asset data"          5 $(sqlCheck)
}

checkAll
