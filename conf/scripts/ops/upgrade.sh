#!/bin/bash
# Full update - assumes update testing on some dev/test machine 

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling $0, expected server address" 1>&2 ; exit 1 ; }

readonly SERVER="$1"
IP=$( jq -r .address "$SERVER/config.json" )

. /opt/dms/conf/scripts/config.sh
. /opt/dms/conf/scripts/lib.sh

# Complete update
APT_FLAGS='-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -q -y'
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo apt-get -y -q update
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_FLAGS dist-upgrade
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo apt-get $APT_FLAGS autoclean
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_FLAGS autoremove

# Reapply nvme patch for i3 servers in case broken by an update
scp $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem /opt/dms/conf/scripts/ops/udev-patch ubuntu@$IP:/tmp/udev-patch
ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo bash /tmp/udev-patch

RebootServer $SERVER

## Force a reboot to install any dist upgrades
#ssh -t -t $SSH_FLAGS -i $AWS_KEY -l ubuntu $IP sudo reboot
## Wait for machine to come up again
#sleep 60s
#ssh -t -t $SSH_FLAGS -i $AWS_KEY -l ubuntu $IP echo "Server up"

# Good luck pause to allow services to start as well
sleep 10s
