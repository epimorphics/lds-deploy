#!/bin/bash
# Check apache status for stuck processes, force apache restart if two processes stalled
#  serverMonitor.sh tierDir

set -o errexit

[[ $# = 1 ]] || { echo "Internal error calling $0" 1>&2 ; exit 1 ; }
readonly tierDir="$1"
readonly SERVERS_BASE=$tierDir/servers

cd /opt/dms/conf/scripts
. ./config.sh
. ./lib.sh
. ./automation_lib.sh

readonly TOPIC_ARN=arn:aws:sns:eu-west-1:853478862498:Nagios-alerts

checkServer() {
    [[ $# = 1 ]] || { echo "Internal error calling checkServer" 1>&2 ; exit 1 ; }
    local server=$1
    IP=$( jq -r .address "$server/config.json" )
    ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "curl -s http://localhost/server-status | tr '\n' ' ' | grep -o '<pre>.*</pre>' | grep -o W | wc -l"
}

apacheRestart() {
    [[ $# = 1 ]] || { echo "Internal error calling apacheRestart" 1>&2 ; exit 1 ; }
    local server=$1
    IP=$( jq -r .address "$server/config.json" )
    ssh -t -t $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP sudo service apache2 restart
}

echo "-- $(date) Starting apache check on $tierDir"
for server in $SERVERS_BASE/*
do
    if grep -q Running $server/status 
    then
        count=$( checkServer $server )
        echo "$Apache write count = $count for $server"
        if (( $count > 40 )); then
            echo "$restarting apache on $server"
            suspendServer $server
            apacheRestart $server
            unsuspendServer $server
            aws sns publish --topic-arn $TOPIC_ARN --subject "Floods server warning" --message "Stuck thread count of $count, restarting apache on $server"
        fi
    fi
done
echo "."
