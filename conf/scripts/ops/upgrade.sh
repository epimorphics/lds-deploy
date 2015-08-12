#!/bin/bash
# Full update - assumes update testing on some dev/test machine 

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling $0, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
readonly IP=$( jq -r .address "$SERVER/config.json" )

. /opt/dms/conf/scripts/config.sh

# Complete update
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo apt-get -y -q update
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade

# Force a reboot to install any dist upgrades
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo reboot

# Wait for machine to come up again
sleep 10s
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP echo "Server up"

# Good luck pause to allow services to start as well
sleep 5s
